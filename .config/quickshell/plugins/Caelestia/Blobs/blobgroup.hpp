#pragma once

#include <qcolor.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlengine.h>

class BlobShape;
class BlobInvertedRect;

class BlobGroup : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(qreal smoothing READ smoothing WRITE setSmoothing NOTIFY smoothingChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(bool proceduralEnabled READ proceduralEnabled WRITE setProceduralEnabled NOTIFY proceduralEnabledChanged)
    Q_PROPERTY(qreal chromeTime READ chromeTime WRITE setChromeTime NOTIFY chromeTimeChanged)
    Q_PROPERTY(qreal chromeScreenWidth READ chromeScreenWidth WRITE setChromeScreenWidth NOTIFY chromeScreenWidthChanged)
    Q_PROPERTY(qreal chromeScreenHeight READ chromeScreenHeight WRITE setChromeScreenHeight NOTIFY chromeScreenHeightChanged)
    Q_PROPERTY(qreal chromeOriginX READ chromeOriginX WRITE setChromeOriginX NOTIFY chromeOriginXChanged)
    Q_PROPERTY(qreal chromeOriginY READ chromeOriginY WRITE setChromeOriginY NOTIFY chromeOriginYChanged)
    Q_PROPERTY(qreal cellSize READ cellSize WRITE setCellSize NOTIFY cellSizeChanged)
    Q_PROPERTY(qreal dotSize READ dotSize WRITE setDotSize NOTIFY dotSizeChanged)
    Q_PROPERTY(qreal animSpeed READ animSpeed WRITE setAnimSpeed NOTIFY animSpeedChanged)
    Q_PROPERTY(qreal intensity READ intensity WRITE setIntensity NOTIFY intensityChanged)
    Q_PROPERTY(QColor color1 READ color1 WRITE setColor1 NOTIFY color1Changed)
    Q_PROPERTY(QColor color2 READ color2 WRITE setColor2 NOTIFY color2Changed)
    Q_PROPERTY(QColor color3 READ color3 WRITE setColor3 NOTIFY color3Changed)
    Q_PROPERTY(QColor baseColor READ baseColor WRITE setBaseColor NOTIFY baseColorChanged)

public:
    explicit BlobGroup(QObject* parent = nullptr);
    ~BlobGroup() override;

    qreal smoothing() const { return m_smoothing; }

    void setSmoothing(qreal s);

    QColor color() const { return m_color; }

    void setColor(const QColor& c);

    bool proceduralEnabled() const { return m_proceduralEnabled; }
    void setProceduralEnabled(bool enabled);

    qreal chromeTime() const { return m_chromeTime; }
    void setChromeTime(qreal t);

    qreal chromeScreenWidth() const { return m_chromeScreenWidth; }
    void setChromeScreenWidth(qreal w);

    qreal chromeScreenHeight() const { return m_chromeScreenHeight; }
    void setChromeScreenHeight(qreal h);

    qreal chromeOriginX() const { return m_chromeOriginX; }
    void setChromeOriginX(qreal x);

    qreal chromeOriginY() const { return m_chromeOriginY; }
    void setChromeOriginY(qreal y);

    qreal cellSize() const { return m_cellSize; }
    void setCellSize(qreal s);

    qreal dotSize() const { return m_dotSize; }
    void setDotSize(qreal s);

    qreal animSpeed() const { return m_animSpeed; }
    void setAnimSpeed(qreal s);

    qreal intensity() const { return m_intensity; }
    void setIntensity(qreal i);

    QColor color1() const { return m_color1; }
    void setColor1(const QColor& c);

    QColor color2() const { return m_color2; }
    void setColor2(const QColor& c);

    QColor color3() const { return m_color3; }
    void setColor3(const QColor& c);

    QColor baseColor() const { return m_baseColor; }
    void setBaseColor(const QColor& c);

    void addShape(BlobShape* shape);
    void removeShape(BlobShape* shape);

    void setInvertedRect(BlobInvertedRect* rect);
    void clearInvertedRect(BlobInvertedRect* rect);

    const QList<BlobShape*>& shapes() const { return m_shapes; }

    BlobInvertedRect* invertedRect() const { return m_invertedRect; }

    void markDirty();
    // Repaint only (uniforms / chrome time) — skips polish + physics
    void markPaintDirty();
    void markShapeDirty(BlobShape* source);
    void ensurePhysicsUpdated();

signals:
    void smoothingChanged();
    void colorChanged();
    void proceduralEnabledChanged();
    void chromeTimeChanged();
    void chromeScreenWidthChanged();
    void chromeScreenHeightChanged();
    void chromeOriginXChanged();
    void chromeOriginYChanged();
    void cellSizeChanged();
    void dotSizeChanged();
    void animSpeedChanged();
    void intensityChanged();
    void color1Changed();
    void color2Changed();
    void color3Changed();
    void baseColorChanged();

private:
    qreal m_smoothing = 32.0;
    QColor m_color{ 0x44, 0x88, 0xff };
    bool m_proceduralEnabled = false;
    qreal m_chromeTime = 0;
    qreal m_chromeScreenWidth = 1920;
    qreal m_chromeScreenHeight = 1080;
    qreal m_chromeOriginX = 50;
    qreal m_chromeOriginY = 50;
    qreal m_cellSize = 7;
    qreal m_dotSize = 0.3;
    qreal m_animSpeed = 0.2;
    qreal m_intensity = 1;
    QColor m_color1{ 0xbb, 0x86, 0xfc };
    QColor m_color2{ 0x40, 0xc4, 0xff };
    QColor m_color3{ 0xff, 0xab, 0x40 };
    QColor m_baseColor{ 0x1a, 0x1a, 0x2e };
    QList<BlobShape*> m_shapes;
    BlobInvertedRect* m_invertedRect = nullptr;
    bool m_physicsUpdated = false;
};
