import type { AstroGlobal } from "astro";

/**
 * EmDash の `getEmDashCollection` / `getEmDashEntry` が返す `cacheHint` を
 * `Astro.cache.set` に渡す。Cloudflare Workers では `Astro.cache` が未定義の
 * ことがあり、その場合に落ちないようにする。
 *
 * @param astro - ページの `Astro` オブジェクト
 * @param cacheHint - EmDash が返すキャッシュヒント（無い場合は何もしない）
 */
export function applyEmDashCacheHint(
	astro: Readonly<AstroGlobal>,
	cacheHint: Parameters<AstroGlobal["cache"]["set"]>[0] | undefined,
): void {
	const cache = astro.cache;
	if (!cache?.set || cacheHint == null) return;
	cache.set(cacheHint);
}
