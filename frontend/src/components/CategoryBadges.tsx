import { Badge } from "@/components/ui/Badge";

interface CategoryBadgesProps {
  categories?: { id?: string; name: string; slug: string }[];
}

/**
 * CategoryBadges — full category list as neutral Badge pills.
 * Unlike the detail header eyebrow (first category only), this renders every category.
 */
export function CategoryBadges({ categories }: CategoryBadgesProps) {
  if (!categories || categories.length === 0) return null;

  return (
    <div className="flex flex-wrap gap-1.5">
      {categories.map((category) => (
        <a
          key={category.id ?? category.slug}
          href={`/search?category=${encodeURIComponent(category.slug)}`}
          className="inline-block"
        >
          <Badge tone="neutral">{category.name}</Badge>
        </a>
      ))}
    </div>
  );
}
