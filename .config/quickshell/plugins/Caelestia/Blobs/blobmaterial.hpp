#pragma once

#include <qcolor.h>
#include <qsgmaterial.h>
#include <qsgmaterialshader.h>

struct BlobRectData {
    float cx = 0, cy = 0, hw = 0, hh = 0;
    float offsetX = 0, offsetY = 0;
    float minEig = 1.0f;
    float invDeform[4] = { 1, 0, 0, 1 };
    float screenHalfX = 0, screenHalfY = 0;
    float radius[4] = { 0, 0, 0, 0 };
    int excludeMask = 0;
};

class BlobMaterial : public QSGMaterial {
public:
    QSGMaterialType* type() const override;
    QSGMaterialShader* createShader(QSGRendererInterface::RenderMode) const override;
    int compare(const QSGMaterial* other) const override;

    float m_paddedX = 0;
    float m_paddedY = 0;
    float m_paddedW = 0;
    float m_paddedH = 0;
    float m_smoothFactor = 32.0f;
    int m_rectCount = 0;
    int m_myIndex = -2;
    QColor m_color{ 0x44, 0x88, 0xff };
    int m_hasInverted = 0;
    float m_invertedRadius = 0;
    float m_invertedOuter[4] = {};
    float m_invertedInner[4] = {};
    BlobRectData m_rects[16] = {};

    float m_chromeTime = 0;
    float m_chromeCellSize = 7;
    float m_chromeDotSize = 0.3f;
    float m_chromeAnimSpeed = 0.2f;
    float m_chromeIntensity = 1;
    float m_chromeScreenW = 1920;
    float m_chromeScreenH = 1080;
    float m_chromeOriginX = 50;
    float m_chromeOriginY = 50;
    int m_chromeEnabled = 0;
    QColor m_chromeColor1;
    QColor m_chromeColor2;
    QColor m_chromeColor3;
    QColor m_chromeBaseColor;
};

class BlobMaterialShader : public QSGMaterialShader {
public:
    BlobMaterialShader();
    bool updateUniformData(RenderState& state, QSGMaterial* newMaterial, QSGMaterial* oldMaterial) override;
};
