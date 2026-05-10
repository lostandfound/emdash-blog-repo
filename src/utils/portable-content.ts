import { markdownToPortableText } from "emdash/client";
import type { PortableTextBlock } from "emdash";

/**
 * API や CLI 経由で portableText フィールドにプレーン文字列（Markdown）が
 * 入っている場合がある。PortableText コンポーネントはブロック配列を想定するため、
 * 表示前に正規化する。
 *
 * @param content - エントリの `content`（配列または Markdown 文字列）
 * @returns Portable Text ブロック配列。空や未対応型は `undefined`
 */
export function toPortableBlocks(
	content: unknown,
): PortableTextBlock[] | undefined {
	if (content == null) return undefined;
	if (Array.isArray(content)) return content as PortableTextBlock[];
	if (typeof content === "string") {
		const trimmed = content.trim();
		if (!trimmed) return undefined;
		return markdownToPortableText(trimmed) as PortableTextBlock[];
	}
	return undefined;
}
