// Springs in Apple's two-parameter terms: `bounce` ≈ 1 − damping ratio,
// `duration` ≈ response. Critically damped by default; bounce only after a flick.
export const spring = { type: 'spring', bounce: 0, duration: 0.45 }
export const springGentle = { type: 'spring', bounce: 0, duration: 0.9 }
export const springFlick = { type: 'spring', bounce: 0.2, duration: 0.5 }

/**
 * Distance a flick travels before coming to rest, using the exponential decay
 * from WWDC's "Designing Fluid Interfaces". decelerationRate ≈ 0.998 feels like
 * a normal scroll; 0.99 is snappier.
 */
export function project(velocity, decelerationRate = 0.998) {
  return ((velocity / 1000) * decelerationRate) / (1 - decelerationRate)
}

export function nearest(points, value) {
  return points.reduce((best, p) => (Math.abs(p - value) < Math.abs(best - value) ? p : best), points[0])
}

export const naira = (n) => `₦${n.toLocaleString('en-NG')}`
