import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone
import math

# 🔑 Firebase setup
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

# 📏 Distance function
def calculate_distance(lat1, lon1, lat2, lon2):
    R = 6371
    dLat = math.radians(lat2 - lat1)
    dLon = math.radians(lon2 - lon1)

    a = math.sin(dLat/2)**2 + math.cos(math.radians(lat1)) * \
        math.cos(math.radians(lat2)) * math.sin(dLon/2)**2

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return R * c


def send_detection_and_alert():
    # 🔥 Step 1: Add detection
    detection_data = {
        "weapon": "Gun",
        "threatLevel": "HIGH",
        "area": "Camera 1",
        "alertSent": False,
        "timestamp": datetime.now(timezone.utc)
    }

    detection_ref = db.collection("detections").add(detection_data)
    print("✅ Detection sent")

    # 🔥 Step 2: Get guards
    users = db.collection("users").get()

    eventLat = 12.9716
    eventLon = 77.5946

    nearest_id = None
    min_distance = float("inf")

    guards = []

    for user in users:
        data = user.to_dict()

        if data.get("isOnline") and data.get("currentLocation"):
            lat = data["currentLocation"]["latitude"]
            lon = data["currentLocation"]["longitude"]

            distance = calculate_distance(eventLat, eventLon, lat, lon)

            guards.append({
                "id": user.id,
                "distance": distance
            })

            if distance < min_distance:
                min_distance = distance
                nearest_id = user.id

    # 🔥 Step 3: Send alerts
    for guard in guards:
        is_nearest = guard["id"] == nearest_id

        db.collection("alerts").add({
            "targetGuardId": guard["id"],
            "type": "priority" if is_nearest else "normal",
            "status": "pending",
            "threatLevel": "HIGH",
            "timestamp": datetime.now(timezone.utc)
        })

    print("🚨 Alerts sent to guards!")


if __name__ == "__main__":
    send_detection_and_alert()