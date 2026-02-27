const { db, admin } = require('../config');
const { getTravelTime, geocodeAddress } = require('../utils');

async function allocateOrderToBestDriver(orderId, pickupCoord, dropoffCoord, weight, callback) {
    try {
        const orderDoc = await db.collection('orders').doc(String(orderId)).get();
        
        if (!pickupCoord || !dropoffCoord) {
             try {
                const newOrder = orderDoc.data();
                pickupCoord = await geocodeAddress(newOrder.pickup_location);
                dropoffCoord = await geocodeAddress(newOrder.dropoff_location);
             } catch(e) {
                 return callback(new Error("Geocoding failed during allocation"));
             }
        }

        const driversSnapshot = await db.collection('drivers').get();
        
        let bestDriver = null;
        let bestScore = Infinity; 
        let bestPlan = null; 

        // 1. Collect all IDs from every driver's route to fetch order data
        let allOrderIds = new Set();
        driversSnapshot.docs.forEach(doc => {
            const d = doc.data();
            if (d.expected_route && d.expected_route.length > 0) {
                d.expected_route.forEach(node => {
                    if (node && node.length > 1 && node !== "") { 
                        allOrderIds.add(node.substring(1));
                    }
                });
            }
        });

        // 2. Fetch those specific orders
        const ordersMap = {};
        const allOrdersSnap = await db.collection('orders').where('status', '!=', 'finished').get();

        allOrdersSnap.forEach(d => {
            const data = d.data();
            if (data.pickup_coordinate && data.dropoff_coordinate) {
                ordersMap[d.id] = {
                    P: { lat: data.pickup_coordinate.latitude, lng: data.pickup_coordinate.longitude },
                    D: { lat: data.dropoff_coordinate.latitude, lng: data.dropoff_coordinate.longitude },
                    weight: parseFloat(data.weight) || 0
                };
            }
        });

        // 3. Add the NEW order
        ordersMap[orderId] = { P: pickupCoord, D: dropoffCoord, weight: weight };

        console.log(`\n===  STARTING ALLOCATION FOR ORDER ${orderId} (Weight: ${weight}kg) ===`);

        for (const doc of driversSnapshot.docs) {
            const driver = { id: parseInt(doc.id, 10), ...doc.data() };
            
            const maxWeight = driver.max_weight || 50;
            const currentRoute = (driver.expected_route || []).filter(node => node !== "");
            const currentTimes = (driver.expected_time && driver.expected_time.length > 0) ? driver.expected_time : [];
            
            const driverLoc = { lat: driver.current_lat || 22.3193, lng: driver.current_lng || 114.1694 };
            const workingTimeParts = driver.working_time ? driver.working_time.split('-') : ["09:00", "18:00"];
            const [startH, startM] = workingTimeParts[0].trim().split(':').map(Number);
            const shiftStartTime = new Date();
            shiftStartTime.setHours(startH, startM, 0, 0);

            const [endH, endM] = workingTimeParts[1].trim().split(':').map(Number);
            const shiftEndTime = new Date();
            shiftEndTime.setHours(endH, endM, 0, 0);

            console.log(`\nChecking Driver ${driver.id} (${driver.name}) | Shift: ${driver.working_time}`);

            // --- INSERTION HEURISTIC ---
            const N = currentRoute.length;
            let bestPlanForDriver = null; 
            let minPenaltyForDriver = Infinity;

            for (let i = 0; i <= N; i++) {
                for (let j = i + 1; j <= N + 1; j++) {
                    
                    let candidateRoute = [...currentRoute];
                    candidateRoute.splice(i, 0, `P${orderId}`);
                    candidateRoute.splice(j, 0, `D${orderId}`); 

                    let valid = true;
                    let tempWeights = [maxWeight]; 
                    let tempTimes = [];
                    let lastLoc = driverLoc;
                    let simulatedCap = maxWeight;
                    
                    let accumulatedTime = (currentTimes.length > 0) ? currentTimes[currentTimes.length - 1] : Date.now();
                    let simAccumulatedTime = Date.now();
                    
                    // 1. capacity check
                    for (const node of candidateRoute) {
                        const type = node.charAt(0);
                        const oid = node.substring(1);
                        const nodeData = ordersMap[oid];
                        
                        if (!nodeData) { valid = false; break; }

                        if (type === 'P') simulatedCap -= nodeData.weight;
                        else simulatedCap += nodeData.weight;

                        if (simulatedCap < 0) {
                            console.log(`  [Skipped] Route P@${i}, D@${j} | Reason: Overcapacity (Load: ${maxWeight - simulatedCap}/${maxWeight}kg)`);
                            valid = false; 
                            break; 
                        }
                        tempWeights.push(simulatedCap);

                        const targetLoc = type === 'P' ? nodeData.P : nodeData.D;
                        const duration = await getTravelTime(lastLoc, targetLoc);
                        simAccumulatedTime += (duration * 1000) + (300 * 1000); 
                        tempTimes.push(simAccumulatedTime);
                        lastLoc = targetLoc;
                    }

                    if (!valid) continue;
                    
                    // 2. time check
                    if (simAccumulatedTime > shiftEndTime.getTime() || simAccumulatedTime < shiftStartTime.getTime()) {
                         console.log(`  [Skipped] Route P@${i}, D@${j} | Reason: Late (Finish: ${new Date(simAccumulatedTime).toLocaleTimeString()})`);
                         valid = false; 
                         continue; 
                    }

                    // 3. scoring
                    const oldEndTime = accumulatedTime;
                    const newEndTime = tempTimes[tempTimes.length - 1];
                    const penaltyTime = newEndTime - oldEndTime;
                    
                    const wTime = 1.0;
                    const wRating = 60000 * 5; // 5 mins per star
                    const rating = driver.avg_rating || 0;
                    
                    const score = (wTime * penaltyTime) - (wRating * rating);

                    console.log(`  [Valid]   Route P@${i}, D@${j} | Penalty: ${(penaltyTime/60000).toFixed(1)}m | Score: ${score.toFixed(0)}`);

                    if (score < minPenaltyForDriver) {
                        minPenaltyForDriver = score;
                        bestPlanForDriver = {
                            route: candidateRoute,
                            weights: tempWeights,
                            times: tempTimes,
                            score: score
                        };
                    }
                }
            }

            if (bestPlanForDriver) {
                console.log(`  => Best for Driver ${driver.id}: Score ${bestPlanForDriver.score.toFixed(0)}`);
                if (bestPlanForDriver.score < bestScore) {
                    bestScore = bestPlanForDriver.score;
                    bestDriver = driver;
                    bestPlan = bestPlanForDriver;
                }
            } else {
                console.log(`  => No valid routes found for Driver ${driver.id}`);
            }
        }

        console.log(`\n===  WINNER: Driver ${bestDriver ? bestDriver.id : 'None'} (Score: ${bestScore !== Infinity ? bestScore.toFixed(0) : 'N/A'}) ===\n`);

        if (!bestDriver) {
             return callback(null, { driverId: null, status: 'pending_no_drivers' });
        }

        // 4. Update Database
        await db.collection('drivers').doc(String(bestDriver.id)).update({
            expected_route: bestPlan.route,
            available_weight: bestPlan.weights,
            expected_time: bestPlan.times
        });

        // 5. Update Order
        let expectedDeliveryTime = null;
        const dropoffNode = `D${orderId}`;
        const dropoffIndex = bestPlan.route.indexOf(dropoffNode);
        if (dropoffIndex !== -1 && bestPlan.times[dropoffIndex]) {
            expectedDeliveryTime = admin.firestore.Timestamp.fromMillis(bestPlan.times[dropoffIndex]);
        }

        await orderDoc.ref.update({ 
            driver_id: bestDriver.id, 
            status: "in_progress",
            pickup_time: admin.firestore.FieldValue.serverTimestamp(),
            expected_delivery_time: expectedDeliveryTime 
        });
        
        callback(null, { driverId: bestDriver.id, cost: bestScore });

    } catch (err) {
        callback(err);
    }
}

module.exports = { allocateOrderToBestDriver };