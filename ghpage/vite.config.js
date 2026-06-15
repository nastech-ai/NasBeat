import tailwindcss from '@tailwindcss/vite';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

const dev = process.env.NODE_ENV === 'development';

export default defineConfig({
	plugins: [tailwindcss(), sveltekit()],
	base: dev ? '/' : '/BloomeeTunes/',
	build: {
		outDir: 'build',
	},
	server: {
		host: '0.0.0.0',
		port: 5000,
		allowedHosts: true,
	},
});
