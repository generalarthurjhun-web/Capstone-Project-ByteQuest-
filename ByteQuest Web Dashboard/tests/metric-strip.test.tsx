import assert from "node:assert/strict";
import test from "node:test";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { CheckCircle2, Users } from "lucide-react";
import { MetricStrip } from "../src/components/dashboard/MetricStrip";

test("metric cards preserve zero values and render authorized destinations as links", () => {
  const markup = renderToStaticMarkup(
    <MetricStrip
      ariaLabel="Instructor metrics"
      metrics={[
        {
          label: "Active learners",
          value: 0,
          helper: "Current active class memberships",
          icon: Users,
          featured: true,
          href: "/progress",
          linkLabel: "Open learner monitoring",
        },
        {
          label: "Released results",
          value: 12,
          helper: "Instructor-final results released",
          icon: CheckCircle2,
          tone: "positive",
        },
      ]}
    />,
  );

  assert.match(markup, /aria-label="Instructor metrics"/);
  assert.match(markup, /href="\/progress"/);
  assert.match(markup, />0<\/p>/);
  assert.match(markup, /bg-primary/);
  assert.match(markup, /text-primary-foreground/);
  assert.match(markup, /Open learner monitoring/);
  assert.match(markup, /Instructor-final results released/);
});

test("metric loading state uses a stable semantic skeleton grid", () => {
  const markup = renderToStaticMarkup(
    <MetricStrip loading ariaLabel="Loading analytics metrics" />,
  );

  assert.match(markup, /role="status"/);
  assert.match(markup, /aria-label="Loading analytics metrics"/);
  assert.equal((markup.match(/min-h-\[132px\]/g) ?? []).length, 4);
});

test("metric error state exposes safe recovery copy without implementation details", () => {
  const markup = renderToStaticMarkup(
    <MetricStrip error ariaLabel="Resource metrics" />,
  );

  assert.match(markup, /role="alert"/);
  assert.match(markup, /Summary metrics are unavailable/);
  assert.doesNotMatch(markup, /SQL|PostgreSQL|stack|exception/i);
});
