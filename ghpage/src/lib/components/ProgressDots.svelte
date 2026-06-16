<script>
  export let count = 4;
  export let index = 0;
  export let onChange = (i) => {};
  export let visible = true;

  const labels = ['Home', 'Awards', 'Features', 'Download', 'About'];

  function setActive(i) {
    if (i === index) return;
    onChange?.(i);
  }
</script>

<!-- Desktop: left-side vertical dots (unchanged behavior) -->
<!-- Mobile: bottom pill dock that slides in/out with spring -->

<div class="progress-indicator" class:hidden={!visible}>
  <!-- Arrow hint — pulses upward when dock first appears on mobile -->
  <div class="dock-arrow" aria-hidden="true">
    <i class="fa-solid fa-chevron-up"></i>
    <i class="fa-solid fa-chevron-up"></i>
  </div>

  <div class="progress-dots" role="tablist" aria-label="Sections">
    {#each Array.from({ length: count }) as _, i}
      <button
        type="button"
        class="dot {i === index ? 'active' : ''}"
        role="tab"
        aria-selected={i === index}
        aria-controls={`section-${i}`}
        aria-label={labels[i] ?? `Section ${i + 1}`}
        title={labels[i] ?? `Section ${i + 1}`}
        on:click={() => setActive(i)}
      >
        <span class="dot-label">{labels[i] ?? i + 1}</span>
      </button>
    {/each}
  </div>
</div>

<style>
  /* ── Desktop: left-side vertical navigator (unchanged) ──────────────────── */
  .progress-indicator {
    width: 80px;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    z-index: 10;
    gap: 0;
  }

  .dock-arrow { display: none; }

  .progress-dots {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }

  .dot {
    position: relative;
    width: 12px;
    height: 12px;
    background-color: rgba(255, 255, 255, 0.4);
    border-radius: 50%;
    transition: all 0.4s ease;
    cursor: pointer;
    border: 1px solid rgba(255, 255, 255, 0.2);
    box-shadow: 0 0 5px rgba(255, 255, 255, 0.2);
    padding: 0;
    overflow: visible;
  }

  .dot.active {
    background-color: #ffffff;
    transform: scale(1.8);
    box-shadow: 0 0 15px rgba(255, 255, 255, 0.8), 0 0 25px rgba(255, 255, 255, 0.4);
    border-color: rgba(255, 255, 255, 0.6);
  }

  /* Desktop: hide label inside dot */
  .dot-label { display: none; }

  /* ── Mobile: glassy bottom dock ──────────────────────────────────────────── */
  @media (max-width: 992px) {
    .progress-indicator {
      position: fixed;
      bottom: 15px;
      left: 50%;
      transform: translateX(-50%) translateY(0);
      width: auto;
      height: auto;
      background: rgba(0, 0, 0, 0.55);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border-radius: 30px;
      padding: 10px 22px;
      border: 1px solid rgba(255, 255, 255, 0.12);
      z-index: 1000;
      box-shadow:
        0 4px 24px rgba(0, 0, 0, 0.4),
        inset 0 1px 0 rgba(255, 255, 255, 0.08);
      flex-direction: column;
      align-items: center;
      gap: 4px;
      /* Spring entrance */
      transition: transform 0.45s cubic-bezier(0.34, 1.56, 0.64, 1),
                  opacity 0.35s ease;
      opacity: 1;
      animation: dockBounceIn 0.55s cubic-bezier(0.34, 1.56, 0.64, 1) both;
    }

    .progress-indicator.hidden {
      transform: translateX(-50%) translateY(130%);
      opacity: 0;
      pointer-events: none;
    }

    /* Arrow hint — two stacked chevrons that fade out after dock appears */
    .dock-arrow {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 2px;
      margin-bottom: 4px;
      animation: arrowPulse 1.4s ease-out 0.2s forwards;
      opacity: 0;
    }

    .dock-arrow i {
      font-size: 9px;
      color: rgba(255, 255, 255, 0.5);
      display: block;
    }

    .progress-dots {
      flex-direction: row;
      gap: 18px;
    }

    .dot {
      position: relative;
      width: 10px;
      height: 10px;
      background-color: rgba(255, 255, 255, 0.3);
      box-shadow: 0 0 3px rgba(255, 255, 255, 0.2);
    }

    .dot.active {
      transform: scale(1.6);
      background-color: #ffffff;
      box-shadow: 0 0 10px rgba(255, 255, 255, 0.8), 0 0 20px rgba(255, 255, 255, 0.4);
    }

    /* Show label as tooltip on active dot */
    .dot.active .dot-label {
      display: block;
      position: absolute;
      bottom: 18px;
      left: 50%;
      transform: translateX(-50%);
      font-size: 9px;
      font-weight: 600;
      color: rgba(255, 255, 255, 0.9);
      white-space: nowrap;
      pointer-events: none;
      text-shadow: 0 1px 4px rgba(0,0,0,0.8);
      letter-spacing: 0.3px;
    }

    @keyframes dockBounceIn {
      0%   { transform: translateX(-50%) translateY(120%); opacity: 0; }
      60%  { transform: translateX(-50%) translateY(-6%);  opacity: 1; }
      80%  { transform: translateX(-50%) translateY(3%);   }
      100% { transform: translateX(-50%) translateY(0);    opacity: 1; }
    }

    @keyframes arrowPulse {
      0%   { opacity: 0; transform: translateY(4px); }
      30%  { opacity: 0.8; transform: translateY(0); }
      70%  { opacity: 0.6; transform: translateY(-2px); }
      100% { opacity: 0; transform: translateY(-6px); }
    }
  }
</style>
