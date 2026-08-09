from __future__ import annotations

import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[2]
WIZARD = ROOT / "tools" / "vision_validation_wizard.html"


class VisionValidationWizardTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = WIZARD.read_text(encoding="utf-8")

    def test_is_self_contained_and_has_no_network_code(self) -> None:
        self.assertIn('Content-Security-Policy', self.source)
        self.assertIn("connect-src 'none'", self.source)
        self.assertNotIn("<script src=", self.source)
        self.assertNotIn("fetch(", self.source)
        self.assertNotIn("XMLHttpRequest", self.source)
        self.assertNotIn("WebSocket", self.source)
        self.assertIn("uitvoer is niet versleuteld", self.source)

    def test_reencodes_crop_and_hashes_both_source_and_crop(self) -> None:
        self.assertIn("crop.toBlob", self.source)
        self.assertIn("reencodedWithoutMetadata:true", self.source)
        self.assertIn("sourceSha256", self.source)
        self.assertIn("cropSha256", self.source)
        self.assertIn("crypto.subtle.digest('SHA-256'", self.source)
        self.assertIn("originalFilenameExcluded:true", self.source)
        self.assertNotIn("file.name", self.source)
        self.assertIn("record.image?.close?.()", self.source)
        self.assertIn("bitmap?.close?.()", self.source)

    def test_does_not_persist_identifying_or_per_photo_fields(self) -> None:
        self.assertNotIn("remembered.cardGroup", self.source)
        self.assertIn("cardGroup: ''", self.source)
        defaults = self.source.split(
            "function rememberNonIdentifyingDefaults(metadata)", 1
        )[1].split("function emptyRecord(file)", 1)[0]
        self.assertIn("targetProfile: metadata.targetProfile", defaults)
        self.assertIn("diameter: metadata.diameter", defaults)
        for prohibited in (
            "cardGroup:",
            "shotCount:",
            "oldHoles:",
            "patches:",
            "multipleSeries:",
        ):
            self.assertNotIn(prohibited, defaults)

    def test_collects_required_ground_truth(self) -> None:
        for value in (
            "physicalCardGroup",
            "targetProfile",
            "projectileDiameterMm",
            "actualShotCount",
            "oldHoles",
            "patches",
            "multipleSeries",
            "isolated",
            "cluster",
            "overlap",
            "tear",
            "uncertain",
        ):
            self.assertIn(value, self.source)

    def test_writes_only_to_explicit_directory_or_download(self) -> None:
        self.assertIn("showDirectoryPicker", self.source)
        self.assertIn("getDirectoryHandle(subdir,{create:true})", self.source)
        self.assertIn("a.download=name", self.source)

    def test_crop_and_rotation_preserve_coordinate_integrity(self) -> None:
        self.assertIn("clamp(a.x,0,size.w)", self.source)
        self.assertIn("pointercancel", self.source)
        self.assertIn("materializeAnnotationSourcePoints(r)", self.source)
        self.assertIn("renormalizeAnnotations(r)", self.source)
        self.assertIn("rotateRect(r.crop,oldSize,delta)", self.source)
        self.assertIn("sourceX:p.x,sourceY:p.y", self.source)
        self.assertIn(
            "annotationCoordinateSpace:'normalizedTargetCropTopLeft'", self.source
        )

    def test_exports_have_collision_resistant_non_filename_identity(self) -> None:
        self.assertIn("r.sourceSha256.slice(0,12)", self.source)
        self.assertIn(
            "const exportedAnnotations=r.annotations.map(({id,kind,xNormalized,yNormalized})",
            self.source,
        )

    def test_rejects_invalid_positive_measurements(self) -> None:
        self.assertIn("!(diameter>0)||!(distance>0)", self.source)
        self.assertIn("!Number.isInteger(shots)||shots<0", self.source)
        self.assertIn(
            "validSelectValue('targetProfile',r.metadata.targetProfile,null)",
            self.source,
        )
        self.assertIn(
            "validSelectValue('cartridge',r.metadata.cartridge,null)", self.source
        )


if __name__ == "__main__":
    unittest.main()
