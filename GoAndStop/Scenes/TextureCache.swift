import SpriteKit

/// 텍스쳐 캐시 관리자 - 성능 최적화
/// 카드 텍스쳐, 이펙트 텍스쳐 등을 메모리에 캐시하여 재생성 방지
class TextureCache {
    static let shared = TextureCache()

    private var cache = NSCache<NSString, SKTexture>()
    private var preloaded = false

    private init() {
        // 최대 100장 캐시 (48장 앞면 + 1장 뒷면 + 여유)
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB 제한

        // 메모리 경고 시 캐시 정리
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 캐시 접근

    func texture(forKey key: String) -> SKTexture? {
        return cache.object(forKey: key as NSString)
    }

    func setTexture(_ texture: SKTexture, forKey key: String) {
        cache.setObject(texture, forKey: key as NSString)
    }

    // MARK: - 카드 텍스쳐

    func cardTexture(for card: Card) -> SKTexture {
        let key = "card_\(card.id)"
        if let cached = texture(forKey: key) {
            return cached
        }

        let texture = CardRenderer.texture(for: card)
        setTexture(texture, forKey: key)
        return texture
    }

    func cardBackTexture() -> SKTexture {
        let key = "card_back"
        if let cached = texture(forKey: key) {
            return cached
        }

        let texture = CardRenderer.backTexture()
        setTexture(texture, forKey: key)
        return texture
    }

    // MARK: - 프리로딩

    /// 게임 시작 전 모든 카드 텍스쳐를 미리 생성
    func preloadAllCardTextures(completion: @escaping () -> Void) {
        guard !preloaded else {
            completion()
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let deck = Card.createDeck()

            // 뒷면 텍스쳐
            let backTexture = CardRenderer.backTexture()
            self.setTexture(backTexture, forKey: "card_back")

            // 모든 카드 앞면 텍스쳐
            for card in deck {
                let texture = CardRenderer.texture(for: card)
                self.setTexture(texture, forKey: "card_\(card.id)")
            }

            DispatchQueue.main.async {
                self.preloaded = true
                completion()
            }
        }
    }

    // MARK: - 캐시 관리

    func clearCache() {
        cache.removeAllObjects()
        preloaded = false
    }

    @objc private func handleMemoryWarning() {
        // 메모리 경고 시 캐시 50% 정리
        // NSCache가 자동 관리하지만 추가적으로 preloaded 상태 리셋
        preloaded = false
    }
}

// MARK: - CardNode 텍스쳐 캐시 통합

extension CardNode {
    /// 캐시된 텍스쳐를 사용하여 카드 노드 생성
    static func cachedNode(card: Card, faceUp: Bool) -> CardNode {
        let node = CardNode(card: card, faceUp: faceUp)
        // CardNode 내부에서 이미 CardRenderer 사용 중
        // TextureCache를 통해 추가 캐싱 적용
        if faceUp {
            node.texture = TextureCache.shared.cardTexture(for: card)
        } else {
            node.texture = TextureCache.shared.cardBackTexture()
        }
        return node
    }
}
