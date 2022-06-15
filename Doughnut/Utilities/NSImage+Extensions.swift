/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 - 2022 Chris Dyer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import AppKit

extension NSImage {

  static func downSampledImage(withData data: Data, dimension: CGFloat, scale: CGFloat) -> NSImage? {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
      return nil
    }

    let dimensionInPixels = dimension * scale
    let downsampleOptions = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: dimensionInPixels,
    ] as CFDictionary
    guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
      return nil
    }

    let imageSize = CGSize(
      width: CGFloat(downsampledImage.width) / scale,
      height: CGFloat(downsampledImage.height) / scale
    )
    return NSImage(cgImage: downsampledImage, size: imageSize)
  }

  func downSampled(dimension: CGFloat, scale: CGFloat) -> NSImage? {
    guard let data = tiffRepresentation else { return nil }
    return Self.downSampledImage(withData: data, dimension: dimension, scale: scale)
 }

  func jpegRepresentation(withCompressionFactor compressionFactor: CGFloat = 1.0) -> Data? {
    guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    return bitmapRep.representation(using: .jpeg, properties: [:])
  }

  // https://gist.github.com/usagimaru/c0a03ef86b5829fb9976b650ec2f1bf4
  func tinted(with tintColor: NSColor) -> NSImage {
    if isTemplate == false {
      return self
    }

    let image = copy() as! NSImage
    image.lockFocus()

    tintColor.set()

    let imageRect = NSRect(origin: .zero, size: image.size)
    imageRect.fill(using: .sourceIn)

    image.unlockFocus()
    image.isTemplate = false

    return image
  }

}
