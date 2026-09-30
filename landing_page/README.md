# Carpital Consult — landing page

Marketing site for Carpital Consult. React 19 + Vite + Tailwind CSS v4, with [Motion](https://motion.dev) for springs, scroll-linked effects and the draggable gallery.

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # static output in dist/
```

## Editing content

Copy, prices, store links, FAQ, cities and sample trips all live in [`src/content.js`](src/content.js).

Before launch:

- **App Store links** — `stores.client.appStore` and `stores.driver.appStore` are `null`, so those badges show "Coming soon". Add the URLs once the apps are live.
- **Play Store links** — built from the app IDs in the Flutter projects (`com.carpitalconsult.consultlogistics`, `com.automove.automove_driver`). Check they resolve after publishing.
- **Prices** — mirror the defaults in `consult_client`. The live values sit in the `pricing_config` table, so keep the two in step.
- **Terms / privacy URLs** — carried over from the client app, where they are still marked as placeholders.

## Assets

- `public/video/on-the-road.mp4` — the branded truck clip from `consult_client/assets/video/main_bg.mp4`.
- `public/images/*` — Unsplash photography (Unsplash License) and the Carpital logo.
- `src/data/nigeria.js` — state outlines generated from [geoBoundaries](https://www.geoboundaries.org) NGA ADM0/ADM1 (CC BY 4.0), credited in the footer.

## Accessibility

Honours `prefers-reduced-motion` (no scroll effects, autoplay or map animation), `prefers-reduced-transparency` and `prefers-contrast`. The gallery works with drag, trackpad swipe, arrow keys and the paddle buttons, and the video has a pause control.
