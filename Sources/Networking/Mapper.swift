////
///  Mapper.swift
//

struct Mapper {

    static func mapToObjectArray(_ dicts: [[String: Any]], type mappingType: MappingType) -> [JSONAble] {
        return dicts.flatMap { object in
            return mapToObject(object, type: mappingType)
        }
    }

    static func mapToObject(_ object: [String: Any], type mappingType: MappingType) -> JSONAble? {
        guard let jsonable = mappingType.fromJSON?(object) else { return nil }

        if let id = (jsonable as? JSONSaveable)?.tableId {
            ElloLinkedStore.shared.saveObject(jsonable, id: id, type: mappingType)
        }
        return jsonable
    }
}
