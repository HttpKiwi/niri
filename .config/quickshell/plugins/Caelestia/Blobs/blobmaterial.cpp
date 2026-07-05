#include "blobmaterial.hpp"

#include <cstring>

static_assert(sizeof(decltype(BlobRectData::excludeMask)) == sizeof(float),
    "BlobMaterial packs excludeMask into a float slot via memcpy");

QSGMaterialType* BlobMaterial::type() const {
    static QSGMaterialType s_type;
    return &s_type;
}

QSGMaterialShader* BlobMaterial::createShader(QSGRendererInterface::RenderMode) const {
    return new BlobMaterialShader;
}

int BlobMaterial::compare(const QSGMaterial* other) const {
    if (this < other)
        return -1;
    if (this > other)
        return 1;
    return 0;
}

BlobMaterialShader::BlobMaterialShader() {
    setShaderFileName(VertexStage, QStringLiteral(":/Caelestia/Blobs/shaders/blob.vert.qsb"));
    setShaderFileName(FragmentStage, QStringLiteral(":/Caelestia/Blobs/shaders/blob.frag.qsb"));
}

bool BlobMaterialShader::updateUniformData(RenderState& state, QSGMaterial* newMaterial, QSGMaterial* oldMaterial) {
    Q_UNUSED(oldMaterial);
    auto* mat = static_cast<BlobMaterial*>(newMaterial);
    QByteArray* buf = state.uniformData();
    Q_ASSERT(buf->size() >= 1552);

    if (state.isMatrixDirty()) {
        const QMatrix4x4 m = state.combinedMatrix();
        memcpy(buf->data(), m.constData(), 64);
    }
    if (state.isOpacityDirty()) {
        const float opacity = state.opacity();
        memcpy(buf->data() + 64, &opacity, 4);
    }

    memcpy(buf->data() + 68, &mat->m_paddedX, 4);
    memcpy(buf->data() + 72, &mat->m_paddedY, 4);
    memcpy(buf->data() + 76, &mat->m_paddedW, 4);
    memcpy(buf->data() + 80, &mat->m_paddedH, 4);

    memcpy(buf->data() + 84, &mat->m_smoothFactor, 4);

    memcpy(buf->data() + 88, &mat->m_rectCount, 4);

    memcpy(buf->data() + 92, &mat->m_myIndex, 4);

    const float color[4] = {
        static_cast<float>(mat->m_color.redF()),
        static_cast<float>(mat->m_color.greenF()),
        static_cast<float>(mat->m_color.blueF()),
        static_cast<float>(mat->m_color.alphaF()),
    };
    memcpy(buf->data() + 96, color, 16);

    memcpy(buf->data() + 112, &mat->m_hasInverted, 4);

    memcpy(buf->data() + 116, &mat->m_invertedRadius, 4);

    memcpy(buf->data() + 128, mat->m_invertedOuter, 16);

    memcpy(buf->data() + 144, mat->m_invertedInner, 16);

    const int count = qMin(mat->m_rectCount, 16);
    for (int i = 0; i < count; ++i) {
        const auto& r = mat->m_rects[i];
        const int base = 160 + i * 80;
        float maskAsFloat;
        memcpy(&maskAsFloat, &r.excludeMask, sizeof(float));
        const float d0[4] = { r.cx, r.cy, r.hw, r.hh };
        const float d1[4] = { maskAsFloat, r.offsetX, r.offsetY, r.minEig };
        const float d3[4] = { r.screenHalfX, r.screenHalfY, 0.0f, 0.0f };
        memcpy(buf->data() + base, d0, 16);
        memcpy(buf->data() + base + 16, d1, 16);
        memcpy(buf->data() + base + 32, r.invDeform, 16);
        memcpy(buf->data() + base + 48, d3, 16);
        memcpy(buf->data() + base + 64, r.radius, 16);
    }

    memcpy(buf->data() + 1440, &mat->m_chromeTime, 4);
    memcpy(buf->data() + 1444, &mat->m_chromeCellSize, 4);
    memcpy(buf->data() + 1448, &mat->m_chromeDotSize, 4);
    memcpy(buf->data() + 1452, &mat->m_chromeAnimSpeed, 4);
    memcpy(buf->data() + 1456, &mat->m_chromeIntensity, 4);
    memcpy(buf->data() + 1460, &mat->m_chromeScreenW, 4);
    memcpy(buf->data() + 1464, &mat->m_chromeScreenH, 4);
    memcpy(buf->data() + 1468, &mat->m_chromeOriginX, 4);
    memcpy(buf->data() + 1472, &mat->m_chromeOriginY, 4);
    memcpy(buf->data() + 1476, &mat->m_chromeEnabled, 4);

    const float chromeColor1[4] = {
        static_cast<float>(mat->m_chromeColor1.redF()),
        static_cast<float>(mat->m_chromeColor1.greenF()),
        static_cast<float>(mat->m_chromeColor1.blueF()),
        static_cast<float>(mat->m_chromeColor1.alphaF()),
    };
    const float chromeColor2[4] = {
        static_cast<float>(mat->m_chromeColor2.redF()),
        static_cast<float>(mat->m_chromeColor2.greenF()),
        static_cast<float>(mat->m_chromeColor2.blueF()),
        static_cast<float>(mat->m_chromeColor2.alphaF()),
    };
    const float chromeColor3[4] = {
        static_cast<float>(mat->m_chromeColor3.redF()),
        static_cast<float>(mat->m_chromeColor3.greenF()),
        static_cast<float>(mat->m_chromeColor3.blueF()),
        static_cast<float>(mat->m_chromeColor3.alphaF()),
    };
    const float chromeBaseColor[4] = {
        static_cast<float>(mat->m_chromeBaseColor.redF()),
        static_cast<float>(mat->m_chromeBaseColor.greenF()),
        static_cast<float>(mat->m_chromeBaseColor.blueF()),
        static_cast<float>(mat->m_chromeBaseColor.alphaF()),
    };
    memcpy(buf->data() + 1488, chromeColor1, 16);
    memcpy(buf->data() + 1504, chromeColor2, 16);
    memcpy(buf->data() + 1520, chromeColor3, 16);
    memcpy(buf->data() + 1536, chromeBaseColor, 16);

    return true;
}
