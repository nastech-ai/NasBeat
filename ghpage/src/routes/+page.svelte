<script>
	import { base } from '$app/paths';
	import Background from '$lib/components/Background.svelte';
	import AssetFigure from '$lib/components/AssetFigure.svelte';
	import ProgressDots from '$lib/components/ProgressDots.svelte';
	import SupportButtons from '$lib/components/SupportButtons.svelte';
	import FeaturesCarousel from '$lib/components/FeaturesCarousel.svelte';
	import AwardsGrid from '$lib/components/AwardsGrid.svelte';
	import DownloadButtons from '$lib/components/DownloadButtons.svelte';
	import AboutDeveloper from '$lib/components/AboutDeveloper.svelte';

	const hero = `${base}/assets/im.webp`;

	let active = $state(0);
	const total = 5;
	let isMobile = $state(false);
	let contentWrapper;
	let dockVisible = $state(true);
	let miniPlayerVisible = $state(false);

	// Mini player simulates the app's now-playing bar for marketing
	let mpPlaying = $state(false);

	function setActive(i) {
		active = i;
		if (isMobile && contentWrapper) {
			const section = contentWrapper.querySelector(`#section-${i}`);
			if (section) section.scrollIntoView({ behavior: 'smooth' });
		}
	}

	function checkMobile() {
		isMobile = window.innerWidth <= 992;
	}

	let throttle = false;

	$effect(() => {
		checkMobile();
		const onResize = () => checkMobile();
		addEventListener('resize', onResize);

		// Desktop: wheel navigation
		const onWheel = (e) => {
			if (isMobile || throttle) return;
			throttle = true;
			let next = active;
			if (e.deltaY > 0) { if (next < total - 1) next++; }
			else { if (next > 0) next--; }
			if (next !== active) active = next;
			setTimeout(() => (throttle = false), 600);
		};

		// Desktop: touch/swipe navigation
		let touchStartY = 0;
		let touchLastY = 0;
		const onTouchStart = (e) => {
			if (isMobile) return;
			touchStartY = touchLastY = e.touches[0].clientY;
		};
		const onTouchMove = (e) => {
			if (isMobile) return;
			touchLastY = e.touches[0].clientY;
		};
		const onTouchEnd = () => {
			if (isMobile) return;
			const dy = touchLastY - touchStartY;
			if (Math.abs(dy) < 35) return;
			let next = active;
			if (dy < 0) { if (next < total - 1) next++; } else { if (next > 0) next--; }
			if (next !== active) active = next;
		};

		addEventListener('wheel', onWheel, { passive: true });
		addEventListener('touchstart', onTouchStart, { passive: true });
		addEventListener('touchmove', onTouchMove, { passive: true });
		addEventListener('touchend', onTouchEnd, { passive: true });

		return () => {
			removeEventListener('wheel', onWheel);
			removeEventListener('touchstart', onTouchStart);
			removeEventListener('touchmove', onTouchMove);
			removeEventListener('touchend', onTouchEnd);
			removeEventListener('resize', onResize);
		};
	});

	// Mobile scroll: track active section + dock/mini-player visibility
	$effect(() => {
		if (!contentWrapper || !isMobile) return;

		let lastScrollTop = 0;
		let dockHideTimer = null;

		const onScroll = () => {
			const scrollTop = contentWrapper.scrollTop;
			const maxScroll = contentWrapper.scrollHeight - contentWrapper.clientHeight;
			const containerHeight = contentWrapper.clientHeight;
			const sections = contentWrapper.querySelectorAll('.content-section');

			// Update active section
			let newActive = 0;
			sections.forEach((section, i) => {
				const sectionTop = section.offsetTop;
				const sectionBottom = sectionTop + section.offsetHeight;
				if (scrollTop >= sectionTop - containerHeight / 3 && scrollTop < sectionBottom - containerHeight / 3) {
					newActive = i;
				}
			});
			if (newActive !== active) active = newActive;

			// Scroll direction → dock & mini player show/hide
			const scrollingDown = scrollTop > lastScrollTop;
			lastScrollTop = scrollTop;

			const nearBottom = scrollTop >= maxScroll - 60;
			const pastHero = scrollTop > 80;

			if (scrollingDown && pastHero) {
				// Show mini player first, then dock after 250ms
				miniPlayerVisible = true;
				clearTimeout(dockHideTimer);
				dockHideTimer = setTimeout(() => { dockVisible = true; }, 250);
			} else if (!scrollingDown && !nearBottom) {
				// Hide dock first, then mini player after 200ms
				dockVisible = false;
				clearTimeout(dockHideTimer);
				dockHideTimer = setTimeout(() => { miniPlayerVisible = false; }, 200);
			}

			// Always show both when near bottom
			if (nearBottom) {
				miniPlayerVisible = true;
				dockVisible = true;
			}
		};

		contentWrapper.addEventListener('scroll', onScroll, { passive: true });
		return () => {
			if (contentWrapper) contentWrapper.removeEventListener('scroll', onScroll);
			clearTimeout(dockHideTimer);
		};
	});
</script>

<svelte:head>
	<title>NasBeat</title>
	<meta name="description" content="NasBeat — Multi-source and open music app for free." />
</svelte:head>

<Background />
<AssetFigure src={hero} alt="Character listening to music" />

<div class="main-container" class:mobile={isMobile}>
	<ProgressDots count={total} index={active} onChange={setActive} visible={dockVisible} />

	<div class="content-wrapper" bind:this={contentWrapper}>
		<section id="section-0" class="content-section {active === 0 ? 'active' : ''}" aria-hidden={active !== 0}>
			<div class="brand-header">
				<img src="/nasbeat-logo-red.png" class="brand-logo" alt="NasBeat logo" />
				<h1 class="home-title">NasBeat</h1>
			</div>
			<p class="home-subtitle">Multi-source and open music app for free.</p>
			<div class="support-message" role="region" aria-label="Support NasBeat">
				<span class="lead">Keep NasBeat alive!</span>
				<span class="msg">Your support today fuels every <span class="highlight">future update</span>, keeps NasBeat <span class="highlight">ad-free</span>, and ensures the tunes <span class="highlight">never stop</span>. ✨</span>
			</div>
			<SupportButtons />
		</section>

		<section id="section-1" class="content-section {active === 1 ? 'active' : ''}" aria-hidden={active !== 1}>
			<h2>SourceForge Awards</h2>
			<p class="section-subtitle">Proudly recognized by the SourceForge community — achieved out of 500,000+ open source projects.</p>
			<AwardsGrid />
		</section>

		<section id="section-2" class="content-section {active === 2 ? 'active' : ''}" aria-hidden={active !== 2}>
			<FeaturesCarousel />
		</section>

		<section id="section-3" class="content-section {active === 3 ? 'active' : ''}" aria-hidden={active !== 3}>
			<h2>Download Now</h2>
			<DownloadButtons />
		</section>

		<section id="section-4" class="content-section {active === 4 ? 'active' : ''}" aria-hidden={active !== 4}>
			<AboutDeveloper />
		</section>
	</div>
</div>

<!-- Mini player bar: marketing preview of the in-app now-playing experience -->
<div class="mini-player" class:visible={miniPlayerVisible} role="region" aria-label="Mini player preview">
	<div class="mp-art">
		<img src="/nasbeat-logo-red.png" alt="NasBeat" />
	</div>
	<div class="mp-info">
		<span class="mp-title">NasBeat is playing</span>
		<span class="mp-artist">Your music, your way</span>
	</div>
	<div class="mp-controls">
		<button class="mp-btn" aria-label="Previous" on:click={() => { if (active > 0) setActive(active - 1); }}>
			<i class="fa-solid fa-backward-step"></i>
		</button>
		<button class="mp-btn mp-play" aria-label="{mpPlaying ? 'Pause' : 'Play'}" on:click={() => (mpPlaying = !mpPlaying)}>
			<i class="fa-solid {mpPlaying ? 'fa-pause' : 'fa-play'}"></i>
		</button>
		<button class="mp-btn" aria-label="Next" on:click={() => { if (active < total - 1) setActive(active + 1); }}>
			<i class="fa-solid fa-forward-step"></i>
		</button>
	</div>
</div>

<style>
	/* ── Desktop layout ─────────────────────────────────────────────────────── */
	.main-container {
		display: flex;
		height: 100vh;
		width: 100vw;
		position: relative;
		z-index: 4;
		overflow: hidden;
	}

	.content-wrapper {
		flex-grow: 1;
		height: 100%;
		position: relative;
	}

	.content-section {
		position: absolute;
		inset: 0;
		display: flex;
		flex-direction: column;
		justify-content: center;
		padding-left: 5%;
		padding-right: 55%;
		opacity: 0;
		transform: translateY(30px);
		transition: opacity 0.45s ease, transform 0.45s ease;
		pointer-events: none;
	}

	.content-section h2 {
		font-size: 2.5rem;
		font-weight: 700;
		background: linear-gradient(45deg, #ff8a00, #e52e71);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		text-align: center;
		margin-bottom: 1.5rem;
		letter-spacing: 1px;
	}

	.content-section.active {
		opacity: 1;
		transform: translateY(0);
		pointer-events: auto;
	}

	.brand-header {
		display: flex;
		align-items: center;
		gap: 1rem;
		margin-bottom: 0;
	}

	.brand-logo {
		width: 64px;
		height: 64px;
		object-fit: contain;
		filter: drop-shadow(0 0 12px rgba(220, 30, 30, 0.5));
	}

	.home-title {
		font-family: 'Borel', sans-serif;
		font-size: 4.5rem;
		font-weight: 700;
		font-style: italic;
		margin-bottom: 0.2rem;
		margin-top: 0;
		text-shadow: 0 0 15px rgba(200, 150, 255, 0.4);
	}

	.home-subtitle {
		font-family: 'Borel', cursive;
		font-weight: 700;
		font-style: normal;
		font-size: 1.4rem;
		color: rgba(255, 237, 248, 0.949);
		margin-top: -0.8rem;
		margin-bottom: 0.8rem;
		max-width: 700px;
		letter-spacing: 0.3px;
		background: linear-gradient(45deg, #ff5258, #ffd48e);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		line-height: 1.2;
		padding-top: 0.6rem;
	}

	h2 {
		font-size: 2.5rem;
		margin-bottom: 1.5rem;
		letter-spacing: 1px;
	}

	.section-subtitle {
		font-family: 'Borel', cursive;
		font-weight: 700;
		font-style: normal;
		font-size: 1.4rem;
		color: rgba(255, 237, 248, 0.949);
		margin-top: 0.1rem;
		margin-bottom: 0.8rem;
		max-width: 700px;
		letter-spacing: 0.3px;
		line-height: 1.2;
		padding-top: 0.6rem;
		text-align: center;
		margin-left: auto;
		margin-right: auto;
		background: linear-gradient(45deg, #ff5258, #ffd48e);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
	}

	.support-message {
		font-family: 'IBM Plex Sans', 'Montserrat', sans-serif;
		font-size: 1.1rem;
		font-weight: 500;
		color: rgb(255, 255, 255);
		margin-bottom: 1.8rem;
		max-width: 480px;
		line-height: 1.6;
		text-shadow: 0 2px 8px rgba(0, 0, 0, 0.645);
		padding: 1rem 1.2rem;
		background: rgba(255, 255, 255, 0.05);
		border-left: 3px solid rgb(235, 49, 111);
		border-radius: 8px;
		backdrop-filter: blur(10px);
	}

	.support-message .highlight {
		color: #ff5258;
		font-weight: 700;
		text-shadow: none;
	}

	.content-section h2,
	.section-subtitle {
		max-width: 720px;
		margin-left: auto;
		margin-right: auto;
	}

	/* ── Mini player (marketing preview, mobile only) ───────────────────────── */
	.mini-player {
		display: none;
	}

	/* ── Mobile layout ──────────────────────────────────────────────────────── */
	@media (max-width: 992px) {
		.main-container {
			flex-direction: column;
			height: 100vh;
			overflow: hidden;
		}

		.content-wrapper {
			flex: 1;
			overflow-y: auto;
			padding-bottom: 140px; /* space for mini player + dock */
			scroll-behavior: smooth;
			height: 100%;
		}

		.content-section {
			position: relative;
			padding: 20px 15px;
			padding-top: 34px;
			justify-content: flex-start;
			background: rgba(16, 11, 33, 0.15);
			backdrop-filter: blur(25px);
			-webkit-backdrop-filter: blur(25px);
			border-radius: 15px;
			margin: 10px 12px;
			min-height: auto;
			transform: none;
			opacity: 1;
			pointer-events: auto;
			display: flex;
			flex-direction: column;
			justify-content: flex-start;
			transition: none;
		}

		.content-section h2,
		.section-subtitle {
			max-width: 90%;
			margin-left: auto;
			margin-right: auto;
		}

		.brand-header { gap: 0.6rem; }
		.brand-logo { width: 44px; height: 44px; }
		.home-title {
			font-size: clamp(2.2rem, 8vw, 3rem);
			line-height: 1.2;
			margin-bottom: 1rem;
			font-weight: 800;
		}
		.home-subtitle {
			font-size: clamp(0.8rem, 6vw, 1.2rem);
			line-height: 1.3;
			margin-bottom: 1rem;
			font-weight: 600;
		}
		.content-section h2 {
			font-size: clamp(1.0rem, 7vw, 1.6rem);
			margin-bottom: 1.2rem;
			line-height: 1.2;
			font-weight: 700;
		}
		.section-subtitle {
			font-weight: 700;
			font-size: clamp(0.9rem, 4.5vw, 1.1rem);
			line-height: 1.4;
			margin-bottom: 1rem;
			max-width: none;
		}
		.support-message {
			font-size: clamp(0.85rem, 3.8vw, 1rem);
			font-weight: 400;
			line-height: 1.5;
			margin-bottom: 1.5rem;
			max-width: none;
			padding: 0.8rem 1rem;
			background: rgba(255, 255, 255, 0.08);
			border-radius: 6px;
			backdrop-filter: blur(8px);
		}

		/* Mini player: visible on mobile when scrolling */
		.mini-player {
			display: flex;
			position: fixed;
			bottom: 68px; /* sits just above the dock pill */
			left: 50%;
			transform: translateX(-50%) translateY(130%);
			width: min(420px, calc(100% - 32px));
			height: 62px;
			background: rgba(0, 0, 0, 0.52);
			backdrop-filter: blur(22px);
			-webkit-backdrop-filter: blur(22px);
			border: 1px solid rgba(255, 255, 255, 0.09);
			border-radius: 18px;
			align-items: center;
			padding: 0 14px;
			gap: 12px;
			z-index: 999;
			box-shadow:
				0 8px 32px rgba(0, 0, 0, 0.45),
				inset 0 1px 0 rgba(255, 255, 255, 0.06);
			transition: transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1),
						opacity 0.35s ease;
			opacity: 0;
			pointer-events: none;
		}

		.mini-player.visible {
			transform: translateX(-50%) translateY(0);
			opacity: 1;
			pointer-events: auto;
		}

		.mp-art {
			width: 38px;
			height: 38px;
			border-radius: 10px;
			overflow: hidden;
			flex-shrink: 0;
			background: rgba(255, 255, 255, 0.05);
			display: flex;
			align-items: center;
			justify-content: center;
		}

		.mp-art img {
			width: 100%;
			height: 100%;
			object-fit: contain;
			filter: drop-shadow(0 0 6px rgba(220, 30, 30, 0.4));
		}

		.mp-info {
			flex: 1;
			display: flex;
			flex-direction: column;
			gap: 2px;
			overflow: hidden;
		}

		.mp-title {
			font-size: 0.82rem;
			font-weight: 600;
			color: rgba(255, 255, 255, 0.95);
			white-space: nowrap;
			overflow: hidden;
			text-overflow: ellipsis;
		}

		.mp-artist {
			font-size: 0.7rem;
			color: rgba(255, 255, 255, 0.5);
			white-space: nowrap;
			overflow: hidden;
			text-overflow: ellipsis;
		}

		.mp-controls {
			display: flex;
			align-items: center;
			gap: 6px;
		}

		.mp-btn {
			background: none;
			border: none;
			color: rgba(255, 255, 255, 0.8);
			cursor: pointer;
			padding: 6px;
			border-radius: 8px;
			font-size: 0.9rem;
			transition: color 0.2s ease, background 0.2s ease;
			display: flex;
			align-items: center;
			justify-content: center;
		}

		.mp-btn:hover { color: #fff; background: rgba(255, 255, 255, 0.1); }

		.mp-btn.mp-play {
			background: rgba(255, 255, 255, 0.12);
			color: #fff;
			padding: 8px 10px;
			border-radius: 10px;
			font-size: 1rem;
		}

		.mp-btn.mp-play:hover { background: rgba(255, 255, 255, 0.22); }
	}
</style>
