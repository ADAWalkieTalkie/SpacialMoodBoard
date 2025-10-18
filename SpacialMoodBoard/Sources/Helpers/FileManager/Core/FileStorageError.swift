import Foundation

/// 파일 저장소 공통 에러
enum FileStorageError: LocalizedError {
    case fileNotFound
    case invalidData
    case saveFailed
    case deleteFailed
    case directoryCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "파일을 찾을 수 없습니다."
        case .invalidData:
            return "유효하지 않은 데이터입니다."
        case .saveFailed:
            return "파일 저장에 실패했습니다."
        case .deleteFailed:
            return "파일 삭제에 실패했습니다."
        case .directoryCreationFailed:
            return "디렉토리 생성에 실패했습니다."
        }
    }
}