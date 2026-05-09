import { Ride } from "../models/Ride";
import { IUser, User } from "../models/User";
import findMatches from "./matchRide";

type MatchRideInput = Pick<
  IUser,
  "name" | "currentLocation" | "destination" | "transportMode"
>;

export const matchRide = async (payload: MatchRideInput) => {
  const user = await User.create(payload);
  const matches = await findMatches(user);
  const [matchedUser] = matches;

  if (!matchedUser) {
    return {
      matched: false,
      message: "No nearby passengers found",
    };
  }

  const ride = await Ride.create({
    passengers: [user._id, matchedUser._id],
    pickupPoint: user.currentLocation,
    destination: user.destination,
    estimatedSavings: 40,
    reducedCars: 1,
  });

  return {
    matched: true,
    ride,
    matchedUser,
  };
};
