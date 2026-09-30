import { motion } from 'motion/react'
import { springGentle } from '../lib/motion.js'

/** Rises into place once, the first time it scrolls into view. */
export default function Reveal({ as = 'div', delay = 0, y = 28, amount = 0.3, className, children, ...rest }) {
  const Tag = motion[as]
  return (
    <Tag
      initial={{ opacity: 0, y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount }}
      transition={{ ...springGentle, delay }}
      className={className}
      {...rest}
    >
      {children}
    </Tag>
  )
}
