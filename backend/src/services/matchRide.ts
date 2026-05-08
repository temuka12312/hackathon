import { User, IUser } from "../models/User";

const calculateDistance = (
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
) => {
  return Math.sqrt(Math.pow(a.lat - b.lat, 2) + Math.pow(a.lng - b.lng, 2));
};

const findMatches = async (user: IUser) => {
  const users = await User.find({
    _id: { $ne: user._id },
  });

  return users.filter((candidate) => {
    const currentDistance = calculateDistance(
      user.currentLocation,
      candidate.currentLocation,
    );

    const destinationDistance = calculateDistance(
      user.destination,
      candidate.destination,
    );

    return currentDistance < 0.02 && destinationDistance < 0.03;
  });
};

export default findMatches;
