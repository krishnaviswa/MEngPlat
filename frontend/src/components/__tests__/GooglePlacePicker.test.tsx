import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { GooglePlacePicker } from "@/components/GooglePlacePicker";
import { dashboard } from "@/lib/api";
import type { MapMarker } from "@/lib/mapMarkers";

jest.mock("../../lib/api", () => ({
  dashboard: {
    searchGooglePlaces: jest.fn(),
    linkGooglePlace: jest.fn(),
  },
}));

// Stand-in for the real Leaflet map -- renders one button per marker so a
// "pin click" can be simulated without pulling react-leaflet into jsdom.
// This is the same fake-map technique the S-036 search page tests use for
// BusinessMapClient.
jest.mock("../BusinessMapClient", () => ({
  BusinessMap: ({
    markers,
    onMarkerClick,
    center,
  }: {
    markers: MapMarker[];
    onMarkerClick?: (m: MapMarker) => void;
    center?: [number, number];
  }) => (
    <div data-testid="fake-map" data-center={center ? center.join(",") : ""}>
      {markers.map((m) => (
        <button key={m.id} type="button" onClick={() => onMarkerClick?.(m)}>
          pin: {m.name}
        </button>
      ))}
    </div>
  ),
}));

const searchMock = dashboard.searchGooglePlaces as jest.Mock;
const linkMock = dashboard.linkGooglePlace as jest.Mock;

const CANDIDATES = [
  { place_id: "mock-place-1", name: "Cafe Aroma (Demo Location)", address: "123 Demo St", latitude: 12.97, longitude: 77.59 },
  { place_id: "mock-place-2", name: "Nearby Cafe (Demo)", address: "456 Demo Ave", latitude: 12.98, longitude: 77.6 },
];

describe("GooglePlacePicker (S-048 AC1-5)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // AC1: search box is prefilled with the business name.
  it("prefills the search box with the business name", () => {
    render(
      <GooglePlacePicker businessId="biz-1" businessName="Cafe Aroma" center={null} onLinked={jest.fn()} />,
    );
    expect(screen.getByLabelText("Search Google Places")).toHaveValue("Cafe Aroma");
  });

  // AC2: candidates render as both list rows and map pins, and either selects the same candidate.
  it("renders search results as list rows and map pins sharing one selection", async () => {
    searchMock.mockResolvedValue({ candidates: CANDIDATES });
    render(
      <GooglePlacePicker
        businessId="biz-1"
        businessName="Cafe Aroma"
        center={[13.0827, 80.2707]}
        onLinked={jest.fn()}
      />,
    );

    fireEvent.click(screen.getByRole("button", { name: "Search" }));

    expect(await screen.findByText("Cafe Aroma (Demo Location)")).toBeInTheDocument();
    expect(screen.getByText("Nearby Cafe (Demo)")).toBeInTheDocument();
    expect(screen.getByText("pin: Cafe Aroma (Demo Location)")).toBeInTheDocument();
    expect(screen.getByTestId("fake-map")).toHaveAttribute("data-center", "13.0827,80.2707");

    const confirmBtn = screen.getByRole("button", { name: /link this business/i });
    expect(confirmBtn).toBeDisabled();

    // Selecting via the pin enables Confirm (same selection state as the list row).
    fireEvent.click(screen.getByText("pin: Cafe Aroma (Demo Location)"));
    expect(confirmBtn).not.toBeDisabled();

    // Selecting via the list row also works and updates the pressed state.
    fireEvent.click(screen.getByText("Nearby Cafe (Demo)").closest("button")!);
    expect(screen.getByText("Nearby Cafe (Demo)").closest("button")).toHaveAttribute("aria-pressed", "true");
    expect(screen.getByText("Cafe Aroma (Demo Location)").closest("button")).toHaveAttribute(
      "aria-pressed",
      "false",
    );
  });

  // AC4: zero candidates -> inline empty state with retry, not a blank list or raw error.
  it("shows an inline empty state with retry when search returns zero candidates", async () => {
    searchMock.mockResolvedValue({ candidates: [] });
    render(
      <GooglePlacePicker businessId="biz-1" businessName="Obscure Biz" center={null} onLinked={jest.fn()} />,
    );

    fireEvent.click(screen.getByRole("button", { name: "Search" }));

    expect(await screen.findByText(/no matches found/i)).toBeInTheDocument();
    // Retry is just the same search box + button, still usable.
    expect(screen.getByRole("button", { name: "Search" })).toBeEnabled();
  });

  // AC5: a provider/search failure shows a readable error, not a raw 500.
  it("shows a readable error banner on search failure", async () => {
    searchMock.mockRejectedValue(new Error("Couldn't reach Google Places right now"));
    render(
      <GooglePlacePicker businessId="biz-1" businessName="Cafe Aroma" center={null} onLinked={jest.fn()} />,
    );

    fireEvent.click(screen.getByRole("button", { name: "Search" }));

    expect(await screen.findByRole("alert")).toHaveTextContent("Couldn't reach Google Places right now");
    expect(screen.queryByRole("button", { name: /link this business/i })).not.toBeInTheDocument();
  });

  // AC3: confirming a selection links the place and notifies the caller.
  it("links the selected candidate and calls onLinked on confirm", async () => {
    searchMock.mockResolvedValue({ candidates: CANDIDATES });
    linkMock.mockResolvedValue({ linked: true, place_id: "mock-place-1" });
    const onLinked = jest.fn();
    render(
      <GooglePlacePicker businessId="biz-1" businessName="Cafe Aroma" center={null} onLinked={onLinked} />,
    );

    fireEvent.click(screen.getByRole("button", { name: "Search" }));
    fireEvent.click(await screen.findByText("Cafe Aroma (Demo Location)"));
    fireEvent.click(screen.getByRole("button", { name: /link this business/i }));

    await waitFor(() =>
      expect(linkMock).toHaveBeenCalledWith(
        "biz-1",
        "mock-place-1",
        "Cafe Aroma (Demo Location)",
        "123 Demo St",
      ),
    );
    await waitFor(() => expect(onLinked).toHaveBeenCalledTimes(1));
  });
});
