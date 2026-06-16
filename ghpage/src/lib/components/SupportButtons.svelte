<script>
	export let buttons = [
		{
			type: 'github',
			icon: 'fa-brands fa-github',
			text: 'GitHub Sponsors',
			href: 'https://github.com/sponsors/nastech-ai'
		},
		{
			type: 'paypal',
			icon: 'fa-brands fa-paypal',
			text: 'PayPal',
			href: 'https://paypal.me/nastechplatforms'
		},
		{
			type: 'coffee',
			icon: 'fa-solid fa-mug-hot',
			text: 'Buy a Coffee',
			href: 'https://buymeacoffee.com/nastech'
		}
	];

	export let highlighted = false;
</script>

<div class="support-container" class:highlighted>
	<h3>Support NasBeat ☕</h3>
	<div class="support-buttons">
		{#each buttons as button}
			<a href={button.href} class="support-btn {button.type}" target="_blank" rel="noopener noreferrer">
				{#if button.customIcon}
					<img src={button.customIcon} alt="{button.text} icon" class="btn-icon" />
				{:else}
					<i class="{button.icon} btn-icon"></i>
				{/if}
				<span class="btn-text">{button.text}</span>
			</a>
		{/each}
	</div>
</div>

<style>
	.support-container h3 {
		font-size: 1.2rem;
		font-family: 'Borel', sans-serif;
		font-weight: 500;
		color: #ffffff;
		margin-bottom: 1rem;
	}

	.support-buttons {
		display: flex;
		gap: 0.8rem;
		flex-wrap: wrap;
	}

	.support-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.6rem;
		padding: 0.7rem 1.4rem;
		border-radius: 12px;
		text-decoration: none;
		font-weight: 500;
		font-size: 0.9rem;
		transition: all 0.3s ease;
		position: relative;
		backdrop-filter: blur(10px);
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
		line-height: 1;
	}

	.support-btn:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
	}

	.btn-icon {
		width: 20px;
		height: 20px;
		display: inline-flex;
		align-items: center;
		justify-content: center;
	}

	.btn-icon.fa-solid,
	.btn-icon.fa-brands {
		font-size: 18px;
	}

	.btn-text {
		display: inline-block;
	}

	.support-btn.github {
		background: #238636;
		border: 1px solid rgba(63, 185, 80, 0.5);
		color: white;
	}

	.support-btn.paypal {
		background: #256aff;
		border: 1px solid rgba(95, 131, 238, 0.7);
		color: white;
	}

	.support-btn.coffee {
		background: #ff813f;
		border: 1px solid rgba(255, 129, 63, 0.5);
		color: white;
	}

	.support-container.highlighted .support-btn.github {
		background: rgba(35, 134, 54, 1);
		border-color: rgba(63, 185, 80, 0.8);
		box-shadow:
			0 3px 12px rgba(63, 185, 80, 0.4),
			0 0 20px rgba(63, 185, 80, 0.3);
		animation: softBlink 1s ease-in-out 3;
	}

	.support-container.highlighted .support-btn.paypal {
		background: rgb(69, 112, 255);
		border-color: rgb(67, 146, 255);
		box-shadow:
			0 3px 12px rgba(106, 168, 255, 0.4),
			0 0 20px rgba(101, 161, 245, 0.3);
		animation: softBlink 1s ease-in-out 3;
	}

	.support-container.highlighted h3 {
		color: #ffffff;
		text-shadow: 0 0 8px rgba(255, 255, 255, 0.4);
	}

	@keyframes softBlink {
		0%, 100% { filter: brightness(1); transform: scale(1); }
		50% { filter: brightness(1.1); transform: scale(1.02); }
	}

	@media (max-width: 992px) {
		.support-container {
			margin-top: 1.5rem;
		}

		.support-container h3 {
			text-align: center;
			margin-bottom: 1rem;
		}

		.support-buttons {
			flex-direction: column;
			gap: 0.8rem;
			align-items: stretch;
		}

		.support-btn {
			padding: 0.6rem 1.2rem;
			font-size: 0.85rem;
			text-align: center;
			border-radius: 8px;
		}
	}
</style>
