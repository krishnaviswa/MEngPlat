import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { BusinessPhotoManager } from "@/components/BusinessPhotoManager";
import { photos } from "@/lib/api";

jest.mock("../../lib/api", () => ({
  photos: {
    listForBusiness: jest.fn(),
    upload: jest.fn(),
    delete: jest.fn(),
  },
}));

const listMock = photos.listForBusiness as jest.Mock;
const uploadMock = photos.upload as jest.Mock;
const deleteMock = photos.delete as jest.Mock;

function makeFile(name = "photo.png", type = "image/png") {
  return new File(["fake-bytes"], name, { type });
}

describe("BusinessPhotoManager", () => {
  beforeEach(() => {
    listMock.mockReset();
    uploadMock.mockReset();
    deleteMock.mockReset();
  });

  // S-075 AC1: upload control present and clearly optional (no required validation).
  it("renders an upload control and optional copy, with no existing photos initially", async () => {
    listMock.mockResolvedValue([]);
    render(<BusinessPhotoManager businessId="biz-1" />);
    expect(screen.getByText(/optional/i)).toBeInTheDocument();
    await waitFor(() => expect(listMock).toHaveBeenCalledWith("biz-1"));
    expect(screen.getByText(/add photo/i)).toBeInTheDocument();
  });

  // S-075 AC3: existing photos are listed via the list endpoint on mount.
  it("lists existing photos fetched via photos.listForBusiness", async () => {
    listMock.mockResolvedValue([
      { id: "p1", url: "http://x/p1.png", caption: null },
      { id: "p2", url: "http://x/p2.png", caption: "Storefront" },
    ]);
    render(<BusinessPhotoManager businessId="biz-1" />);
    expect(await screen.findByAltText("Business photo")).toBeInTheDocument();
    expect(screen.getByAltText("Storefront")).toBeInTheDocument();
  });

  // S-075 AC2: selecting a valid image uploads it via photos.upload and it appears
  // immediately in the merchant's own preview.
  it("uploads a selected file and shows it immediately on success", async () => {
    listMock.mockResolvedValue([]);
    uploadMock.mockResolvedValue({ id: "new-1", url: "http://x/new-1.png", caption: null });
    render(<BusinessPhotoManager businessId="biz-1" />);
    await waitFor(() => expect(listMock).toHaveBeenCalled());

    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    const file = makeFile();
    fireEvent.change(input, { target: { files: [file] } });

    await waitFor(() =>
      expect(uploadMock).toHaveBeenCalledWith(file, { businessId: "biz-1", photoType: "gallery" }),
    );
    expect(await screen.findByAltText("Business photo")).toHaveAttribute("src", "http://x/new-1.png");
  });

  // S-075 AC4: a rejected upload (unsupported type / too large) shows a clear, specific
  // inline error, not a silent failure.
  it("shows a specific inline error when the backend rejects the upload", async () => {
    listMock.mockResolvedValue([]);
    uploadMock.mockRejectedValue(new Error("Unsupported file type. Allowed: jpg, png, webp."));
    render(<BusinessPhotoManager businessId="biz-1" />);
    await waitFor(() => expect(listMock).toHaveBeenCalled());

    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    fireEvent.change(input, { target: { files: [makeFile("bad.gif", "image/gif")] } });

    expect(await screen.findByText(/unsupported file type/i)).toBeInTheDocument();
  });

  // S-075 AC3: deletion requires confirmation (window.confirm) before calling photos.delete.
  it("requires confirmation before deleting, and removes the photo from the list on confirm", async () => {
    listMock.mockResolvedValue([{ id: "p1", url: "http://x/p1.png", caption: null }]);
    deleteMock.mockResolvedValue(undefined);
    const confirmSpy = jest.spyOn(window, "confirm").mockReturnValue(true);
    render(<BusinessPhotoManager businessId="biz-1" />);
    await screen.findByAltText("Business photo");

    fireEvent.click(screen.getByRole("button", { name: /remove photo/i }));

    expect(confirmSpy).toHaveBeenCalled();
    await waitFor(() => expect(deleteMock).toHaveBeenCalledWith("p1"));
    await waitFor(() => expect(screen.queryByAltText("Business photo")).not.toBeInTheDocument());
    confirmSpy.mockRestore();
  });

  // S-075 AC3: declining the confirm dialog does not call photos.delete.
  it("does not delete when confirmation is declined", async () => {
    listMock.mockResolvedValue([{ id: "p1", url: "http://x/p1.png", caption: null }]);
    const confirmSpy = jest.spyOn(window, "confirm").mockReturnValue(false);
    render(<BusinessPhotoManager businessId="biz-1" />);
    await screen.findByAltText("Business photo");

    fireEvent.click(screen.getByRole("button", { name: /remove photo/i }));

    expect(confirmSpy).toHaveBeenCalled();
    expect(deleteMock).not.toHaveBeenCalled();
    confirmSpy.mockRestore();
  });
});
