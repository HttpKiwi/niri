#include "blobgroup.hpp"
#include "blobinvertedrect.hpp"
#include "blobshape.hpp"

BlobGroup::BlobGroup(QObject* parent)
    : QObject(parent) {}

BlobGroup::~BlobGroup() {
    for (auto* shape : std::as_const(m_shapes))
        shape->m_group = nullptr;
    if (m_invertedRect)
        static_cast<BlobShape*>(m_invertedRect)->m_group = nullptr;
}

void BlobGroup::setSmoothing(qreal s) {
    if (qFuzzyCompare(m_smoothing, s))
        return;
    m_smoothing = s;
    emit smoothingChanged();
    markDirty();
}

void BlobGroup::setColor(const QColor& c) {
    if (m_color == c)
        return;
    m_color = c;
    emit colorChanged();
    markPaintDirty();
}

// Chrome uniforms only affect the fragment shader — no geometry/physics work
#define CHROME_PAINT_SETTER(Type, name, Name) \
    void BlobGroup::set##Name(Type v) { \
        if (m_##name == v) \
            return; \
        m_##name = v; \
        emit name##Changed(); \
        markPaintDirty(); \
    }

CHROME_PAINT_SETTER(bool, proceduralEnabled, ProceduralEnabled)
CHROME_PAINT_SETTER(qreal, chromeTime, ChromeTime)
CHROME_PAINT_SETTER(qreal, chromeScreenWidth, ChromeScreenWidth)
CHROME_PAINT_SETTER(qreal, chromeScreenHeight, ChromeScreenHeight)
CHROME_PAINT_SETTER(qreal, chromeOriginX, ChromeOriginX)
CHROME_PAINT_SETTER(qreal, chromeOriginY, ChromeOriginY)
CHROME_PAINT_SETTER(qreal, cellSize, CellSize)
CHROME_PAINT_SETTER(qreal, dotSize, DotSize)
CHROME_PAINT_SETTER(qreal, animSpeed, AnimSpeed)
CHROME_PAINT_SETTER(qreal, intensity, Intensity)

void BlobGroup::setColor1(const QColor& c) {
    if (m_color1 == c)
        return;
    m_color1 = c;
    emit color1Changed();
    markPaintDirty();
}

void BlobGroup::setColor2(const QColor& c) {
    if (m_color2 == c)
        return;
    m_color2 = c;
    emit color2Changed();
    markPaintDirty();
}

void BlobGroup::setColor3(const QColor& c) {
    if (m_color3 == c)
        return;
    m_color3 = c;
    emit color3Changed();
    markPaintDirty();
}

void BlobGroup::setBaseColor(const QColor& c) {
    if (m_baseColor == c)
        return;
    m_baseColor = c;
    emit baseColorChanged();
    markPaintDirty();
}

void BlobGroup::addShape(BlobShape* shape) {
    if (!shape || m_shapes.contains(shape))
        return;
    m_shapes.append(shape);
    markDirty();
}

void BlobGroup::removeShape(BlobShape* shape) {
    m_shapes.removeOne(shape);
    markDirty();
}

void BlobGroup::setInvertedRect(BlobInvertedRect* rect) {
    if (m_invertedRect == rect)
        return;
    m_invertedRect = rect;
    markDirty();
}

void BlobGroup::clearInvertedRect(BlobInvertedRect* rect) {
    if (m_invertedRect != rect)
        return;
    m_invertedRect = nullptr;
    markDirty();
}

void BlobGroup::markDirty() {
    m_physicsUpdated = false;
    for (auto* shape : std::as_const(m_shapes)) {
        shape->polish();
        shape->update();
    }
    if (m_invertedRect) {
        static_cast<BlobShape*>(m_invertedRect)->polish();
        static_cast<BlobShape*>(m_invertedRect)->update();
    }
}

void BlobGroup::markPaintDirty() {
    for (auto* shape : std::as_const(m_shapes))
        shape->update();
    if (m_invertedRect)
        static_cast<BlobShape*>(m_invertedRect)->update();
}

void BlobGroup::markShapeDirty(BlobShape* source) {
    m_physicsUpdated = false;

    source->polish();
    source->update();

    const float pad = static_cast<float>(m_smoothing) * 2.0f;
    const QRectF srcRect(static_cast<double>(source->m_cachedPaddedX - pad),
        static_cast<double>(source->m_cachedPaddedY - pad), static_cast<double>(source->m_cachedPaddedW + pad * 2.0f),
        static_cast<double>(source->m_cachedPaddedH + pad * 2.0f));

    for (auto* shape : std::as_const(m_shapes)) {
        if (shape == source)
            continue;
        const QRectF otherRect(static_cast<double>(shape->m_cachedPaddedX), static_cast<double>(shape->m_cachedPaddedY),
            static_cast<double>(shape->m_cachedPaddedW), static_cast<double>(shape->m_cachedPaddedH));
        if (srcRect.intersects(otherRect)) {
            shape->polish();
            shape->update();
        }
    }

    if (m_invertedRect && static_cast<BlobShape*>(m_invertedRect) != source) {
        static_cast<BlobShape*>(m_invertedRect)->polish();
        static_cast<BlobShape*>(m_invertedRect)->update();
    }
}

void BlobGroup::ensurePhysicsUpdated() {
    if (m_physicsUpdated)
        return;
    m_physicsUpdated = true;
    for (auto* shape : std::as_const(m_shapes))
        shape->updatePhysics();
}
