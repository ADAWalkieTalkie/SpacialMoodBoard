import Foundation

protocol FileStorageProtocol {
    associatedtype DataType: Codable
    
    /// 데이터 저장
    func save(_ data: DataType, projectName: String) throws
    
    /// 데이터 로드
    func load(projectName: String) throws -> DataType

    /// 이름 변경
    func rename(from oldName: String, to newName: String) throws
    
    /// 데이터 삭제
    func delete(projectName: String) throws
    
    /// 파일 존재 여부 확인
    func exists(projectName: String) -> Bool
}
