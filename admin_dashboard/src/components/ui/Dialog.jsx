import { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';
import { GlassIconButton } from './Button';

/**
 * Centred dialog on a blurred scrim. Rendered into <body> so no transformed
 * or blurred ancestor can trap it. Pass `as="form"` and `onSubmit` for forms.
 */
export function Dialog({ title, eyebrow, onClose, footer, as: Tag = 'div', width = 'max-w-[560px]', children, ...props }) {
  useEffect(() => {
    const onKey = (e) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  return createPortal(
    <div
      className="fixed inset-0 z-[300] flex items-center justify-center p-6 bg-black/60 backdrop-blur-sm animate-fade"
      onClick={onClose}
    >
      <Tag
        {...props}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(e) => e.stopPropagation()}
        className={`w-full ${width} max-h-full overflow-y-auto scrollbar-thin flex flex-col gap-5 p-6 rounded-dialog border border-white/12 bg-[rgb(21_21_21/0.94)] shadow-float animate-enter`}
      >
        <div className="flex items-start justify-between gap-4">
          <div className="min-w-0">
            {eyebrow && (
              <div className="text-[11px] font-bold uppercase tracking-[1.2px] text-accent-light mb-1">{eyebrow}</div>
            )}
            <h3 className="text-[20px] font-extrabold tracking-[-0.3px] text-white">{title}</h3>
          </div>
          <GlassIconButton icon={X} label="Close" size={36} onClick={onClose} />
        </div>
        {children}
        {footer && <div className="flex flex-wrap justify-end gap-3 pt-1">{footer}</div>}
      </Tag>
    </div>,
    document.body,
  );
}
