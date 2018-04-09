////
///  StreamService.swift
//

import Moya
import PromiseKit


struct StreamLoadedNotifications {
    static let streamLoaded = TypedNotification<StreamKind>(name: "StreamLoadedNotification")
}

class StreamService {
    enum StreamResponse {
        case jsonables([JSONAble], ResponseConfig)
        case empty
    }

    func loadStream(streamKind: StreamKind) -> Promise<StreamResponse> {
        return loadStream(endpoint: streamKind.endpoint, streamKind: streamKind)
    }

    func loadStream(endpoint: ElloAPI, streamKind: StreamKind? = nil) -> Promise<StreamResponse> {
        return ElloProvider.shared.request(endpoint)
            .map { (data, responseConfig) -> StreamResponse in
                if let streamKind = streamKind {
                    nextTick {
                        postNotification(StreamLoadedNotifications.streamLoaded, value: streamKind)
                    }
                }

                let jsonables = (data as? [JSONAble]) ?? (data as? JSONAble).map { [$0] }
                if data as? String == "" {
                    return .empty
                }
                else if let jsonables = jsonables {
                    if let streamKind = streamKind {
                        Preloader().preloadImages(jsonables)
                        NewContentService().updateCreatedAt(jsonables, streamKind: streamKind)
                    }
                    return .jsonables(jsonables, responseConfig)
                }
                else {
                    throw NSError.uncastableJSONAble()
                }
            }
    }
}
