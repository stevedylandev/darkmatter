import { Copy } from "./components/copy";
import { Link } from "@mini_apps/utilities";
import termImage from "./assets/darkmatter.png";

function App() {
	return (
		<main className="flex flex-col min-h-screen w-full items-center justify-center gap-12 bg-[#121113] text-white">
			<h1 className="sm:text-7xl text-5xl font-mono">DARKMATTER</h1>
			<p className="text-xs sm:text-lg font-mono">
				An opinionated terminal setup with Ghostty
			</p>
			<img src={termImage} className="sm:max-w-2xl max-w-sm" alt="screenshot" />
			<Copy />
			<div className="flex flex-col justify-center items-center gap-4">
				<p className="font-mono text-xs sm:text-base">
					Visit GitHub link below for more info
				</p>
				<Link
					href="https://github.com/stevedylandev/darkmatter"
					className="inline-flex items-center justify-center rounded-md font-medium text-sm leading-5 px-4 py-2 bg-[#1a191b] text-[#d1d1d1] cursor-pointer outline-none border border-transparent hover:bg-[#232225] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/80"
				>
					<svg
						xmlns="http://www.w3.org/2000/svg"
						width="32"
						height="32"
						viewBox="0 0 24 24"
						className="h-5 w-5 mr-2"
					>
						<title>github</title>
						<path
							fill="currentColor"
							d="M12 2A10 10 0 0 0 2 12c0 4.42 2.87 8.17 6.84 9.5c.5.08.66-.23.66-.5v-1.69c-2.77.6-3.36-1.34-3.36-1.34c-.46-1.16-1.11-1.47-1.11-1.47c-.91-.62.07-.6.07-.6c1 .07 1.53 1.03 1.53 1.03c.87 1.52 2.34 1.07 2.91.83c.09-.65.35-1.09.63-1.34c-2.22-.25-4.55-1.11-4.55-4.92c0-1.11.38-2 1.03-2.71c-.1-.25-.45-1.29.1-2.64c0 0 .84-.27 2.75 1.02c.79-.22 1.65-.33 2.5-.33s1.71.11 2.5.33c1.91-1.29 2.75-1.02 2.75-1.02c.55 1.35.2 2.39.1 2.64c.65.71 1.03 1.6 1.03 2.71c0 3.82-2.34 4.66-4.57 4.91c.36.31.69.92.69 1.85V21c0 .27.16.59.67.5C19.14 20.16 22 16.42 22 12A10 10 0 0 0 12 2"
						/>
					</svg>
					GitHub
				</Link>
			</div>
		</main>
	);
}

export default App;
