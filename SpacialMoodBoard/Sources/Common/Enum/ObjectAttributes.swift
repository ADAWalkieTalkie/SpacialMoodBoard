enum ObjectAttributes: Codable, Hashable {
    case image(ImageAttributes)
    case audio(AudioAttributes)
}