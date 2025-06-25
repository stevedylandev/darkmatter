import { useState } from "react";

export function Copy() {
	const [copied, setCopied] = useState(false);

	const copyToClipboard = async () => {
		try {
			await navigator.clipboard.writeText(
				"curl -sSL https://darkmatter.build/install.sh | bash",
			);
			setCopied(true);
			setTimeout(() => setCopied(false), 2000);
		} catch (err) {
			console.error("Failed to copy:", err);
		}
	};

	return (
		<div className="max-w-lg w-full">
			<div className="relative rounded-lg bg-zinc-800 p-4 overflow-scroll mx-4 sm:mx-auto">
				<pre className="text-sm font-mono">
					<code>curl -sSL https://darkmatter.build/install.sh | bash</code>
				</pre>
				<button
					type="button"
					className="absolute hidden sm:block top-2.5 right-2 rounded-md p-2 hover:bg-zinc-200 dark:hover:bg-zinc-700 focus:outline-none"
					onClick={copyToClipboard}
				>
					{copied ? (
						<svg
							xmlns="http://www.w3.org/2000/svg"
							width="16"
							height="16"
							viewBox="0 0 24 24"
							fill="none"
							stroke="currentColor"
							strokeWidth="2"
							strokeLinecap="round"
							strokeLinejoin="round"
							className="h-4 w-4"
						>
							<title>Copy</title>
							<polyline points="20 6 9 17 4 12"></polyline>
						</svg>
					) : (
						<svg
							xmlns="http://www.w3.org/2000/svg"
							width="16"
							height="16"
							viewBox="0 0 24 24"
							fill="none"
							stroke="currentColor"
							strokeWidth="2"
							strokeLinecap="round"
							strokeLinejoin="round"
							className="h-4 w-4"
						>
							<title>Copy</title>
							<rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
							<path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
						</svg>
					)}
				</button>
			</div>
		</div>
	);
}
