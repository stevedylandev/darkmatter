import { Copy } from "./components/copy";

function App() {
	return (
		<main className="flex flex-col min-h-screen w-full items-center justify-center gap-12 bg-[#121113] text-white">
			<h1 className="text-7xl font-mono">DARKMATTER</h1>
			<p className="font-mono">An opinionated terminal setup with Ghostty</p>
			<Copy />
		</main>
	);
}

export default App;
