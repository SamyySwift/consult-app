import { Bike, Bus, Car, CarFront, Truck } from 'lucide-react';

const ICONS = { suv: CarFront, truck: Truck, van: Bus, motorcycle: Bike };

export const vehicleIcon = (type) => ICONS[(type || '').toLowerCase()] ?? Car;
