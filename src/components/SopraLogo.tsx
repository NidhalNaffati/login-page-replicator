export const SopraLogo = () => (
  <div className="flex items-center gap-2">
    {/* S icon */}
    <svg width="48" height="48" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path
        d="M12 34C12 34 16 30 24 26C32 22 36 18 36 14C36 10 32 8 28 8C24 8 20 10 18 14"
        stroke="hsl(10, 85%, 50%)"
        strokeWidth="4"
        strokeLinecap="round"
        fill="none"
      />
      <path
        d="M36 14C36 14 32 18 24 22C16 26 12 30 12 34C12 38 16 40 20 40C24 40 28 38 30 34"
        stroke="hsl(25, 90%, 55%)"
        strokeWidth="4"
        strokeLinecap="round"
        fill="none"
      />
    </svg>
    <div className="flex flex-col">
      <span className="text-2xl font-light tracking-widest text-card-foreground" style={{ fontFamily: 'system-ui' }}>
        sopra hr
      </span>
      <span className="text-[10px] font-semibold tracking-[0.35em] uppercase text-muted-foreground">
        Software
      </span>
    </div>
  </div>
);
