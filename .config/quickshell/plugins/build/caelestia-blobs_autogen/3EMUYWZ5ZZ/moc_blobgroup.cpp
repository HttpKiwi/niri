/****************************************************************************
** Meta object code from reading C++ file 'blobgroup.hpp'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../Caelestia/Blobs/blobgroup.hpp"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'blobgroup.hpp' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.11.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN9BlobGroupE_t {};
} // unnamed namespace

template <> constexpr inline auto BlobGroup::qt_create_metaobjectdata<qt_meta_tag_ZN9BlobGroupE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "BlobGroup",
        "QML.Element",
        "auto",
        "smoothingChanged",
        "",
        "colorChanged",
        "proceduralEnabledChanged",
        "chromeTimeChanged",
        "chromeScreenWidthChanged",
        "chromeScreenHeightChanged",
        "chromeOriginXChanged",
        "chromeOriginYChanged",
        "cellSizeChanged",
        "dotSizeChanged",
        "animSpeedChanged",
        "intensityChanged",
        "color1Changed",
        "color2Changed",
        "color3Changed",
        "baseColorChanged",
        "smoothing",
        "color",
        "QColor",
        "proceduralEnabled",
        "chromeTime",
        "chromeScreenWidth",
        "chromeScreenHeight",
        "chromeOriginX",
        "chromeOriginY",
        "cellSize",
        "dotSize",
        "animSpeed",
        "intensity",
        "color1",
        "color2",
        "color3",
        "baseColor"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'smoothingChanged'
        QtMocHelpers::SignalData<void()>(3, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'colorChanged'
        QtMocHelpers::SignalData<void()>(5, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'proceduralEnabledChanged'
        QtMocHelpers::SignalData<void()>(6, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'chromeTimeChanged'
        QtMocHelpers::SignalData<void()>(7, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'chromeScreenWidthChanged'
        QtMocHelpers::SignalData<void()>(8, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'chromeScreenHeightChanged'
        QtMocHelpers::SignalData<void()>(9, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'chromeOriginXChanged'
        QtMocHelpers::SignalData<void()>(10, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'chromeOriginYChanged'
        QtMocHelpers::SignalData<void()>(11, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'cellSizeChanged'
        QtMocHelpers::SignalData<void()>(12, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'dotSizeChanged'
        QtMocHelpers::SignalData<void()>(13, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'animSpeedChanged'
        QtMocHelpers::SignalData<void()>(14, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'intensityChanged'
        QtMocHelpers::SignalData<void()>(15, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'color1Changed'
        QtMocHelpers::SignalData<void()>(16, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'color2Changed'
        QtMocHelpers::SignalData<void()>(17, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'color3Changed'
        QtMocHelpers::SignalData<void()>(18, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'baseColorChanged'
        QtMocHelpers::SignalData<void()>(19, 4, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'smoothing'
        QtMocHelpers::PropertyData<qreal>(20, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'color'
        QtMocHelpers::PropertyData<QColor>(21, 0x80000000 | 22, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 1),
        // property 'proceduralEnabled'
        QtMocHelpers::PropertyData<bool>(23, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'chromeTime'
        QtMocHelpers::PropertyData<qreal>(24, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 3),
        // property 'chromeScreenWidth'
        QtMocHelpers::PropertyData<qreal>(25, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 4),
        // property 'chromeScreenHeight'
        QtMocHelpers::PropertyData<qreal>(26, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 5),
        // property 'chromeOriginX'
        QtMocHelpers::PropertyData<qreal>(27, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 6),
        // property 'chromeOriginY'
        QtMocHelpers::PropertyData<qreal>(28, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 7),
        // property 'cellSize'
        QtMocHelpers::PropertyData<qreal>(29, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 8),
        // property 'dotSize'
        QtMocHelpers::PropertyData<qreal>(30, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 9),
        // property 'animSpeed'
        QtMocHelpers::PropertyData<qreal>(31, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 10),
        // property 'intensity'
        QtMocHelpers::PropertyData<qreal>(32, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 11),
        // property 'color1'
        QtMocHelpers::PropertyData<QColor>(33, 0x80000000 | 22, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 12),
        // property 'color2'
        QtMocHelpers::PropertyData<QColor>(34, 0x80000000 | 22, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 13),
        // property 'color3'
        QtMocHelpers::PropertyData<QColor>(35, 0x80000000 | 22, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 14),
        // property 'baseColor'
        QtMocHelpers::PropertyData<QColor>(36, 0x80000000 | 22, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 15),
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
    });
    return QtMocHelpers::metaObjectData<BlobGroup, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject BlobGroup::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9BlobGroupE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9BlobGroupE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN9BlobGroupE_t>.metaTypes,
    nullptr
} };

void BlobGroup::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<BlobGroup *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->smoothingChanged(); break;
        case 1: _t->colorChanged(); break;
        case 2: _t->proceduralEnabledChanged(); break;
        case 3: _t->chromeTimeChanged(); break;
        case 4: _t->chromeScreenWidthChanged(); break;
        case 5: _t->chromeScreenHeightChanged(); break;
        case 6: _t->chromeOriginXChanged(); break;
        case 7: _t->chromeOriginYChanged(); break;
        case 8: _t->cellSizeChanged(); break;
        case 9: _t->dotSizeChanged(); break;
        case 10: _t->animSpeedChanged(); break;
        case 11: _t->intensityChanged(); break;
        case 12: _t->color1Changed(); break;
        case 13: _t->color2Changed(); break;
        case 14: _t->color3Changed(); break;
        case 15: _t->baseColorChanged(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::smoothingChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::colorChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::proceduralEnabledChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::chromeTimeChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::chromeScreenWidthChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::chromeScreenHeightChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::chromeOriginXChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::chromeOriginYChanged, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::cellSizeChanged, 8))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::dotSizeChanged, 9))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::animSpeedChanged, 10))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::intensityChanged, 11))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::color1Changed, 12))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::color2Changed, 13))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::color3Changed, 14))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobGroup::*)()>(_a, &BlobGroup::baseColorChanged, 15))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<qreal*>(_v) = _t->smoothing(); break;
        case 1: *reinterpret_cast<QColor*>(_v) = _t->color(); break;
        case 2: *reinterpret_cast<bool*>(_v) = _t->proceduralEnabled(); break;
        case 3: *reinterpret_cast<qreal*>(_v) = _t->chromeTime(); break;
        case 4: *reinterpret_cast<qreal*>(_v) = _t->chromeScreenWidth(); break;
        case 5: *reinterpret_cast<qreal*>(_v) = _t->chromeScreenHeight(); break;
        case 6: *reinterpret_cast<qreal*>(_v) = _t->chromeOriginX(); break;
        case 7: *reinterpret_cast<qreal*>(_v) = _t->chromeOriginY(); break;
        case 8: *reinterpret_cast<qreal*>(_v) = _t->cellSize(); break;
        case 9: *reinterpret_cast<qreal*>(_v) = _t->dotSize(); break;
        case 10: *reinterpret_cast<qreal*>(_v) = _t->animSpeed(); break;
        case 11: *reinterpret_cast<qreal*>(_v) = _t->intensity(); break;
        case 12: *reinterpret_cast<QColor*>(_v) = _t->color1(); break;
        case 13: *reinterpret_cast<QColor*>(_v) = _t->color2(); break;
        case 14: *reinterpret_cast<QColor*>(_v) = _t->color3(); break;
        case 15: *reinterpret_cast<QColor*>(_v) = _t->baseColor(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setSmoothing(*reinterpret_cast<qreal*>(_v)); break;
        case 1: _t->setColor(*reinterpret_cast<QColor*>(_v)); break;
        case 2: _t->setProceduralEnabled(*reinterpret_cast<bool*>(_v)); break;
        case 3: _t->setChromeTime(*reinterpret_cast<qreal*>(_v)); break;
        case 4: _t->setChromeScreenWidth(*reinterpret_cast<qreal*>(_v)); break;
        case 5: _t->setChromeScreenHeight(*reinterpret_cast<qreal*>(_v)); break;
        case 6: _t->setChromeOriginX(*reinterpret_cast<qreal*>(_v)); break;
        case 7: _t->setChromeOriginY(*reinterpret_cast<qreal*>(_v)); break;
        case 8: _t->setCellSize(*reinterpret_cast<qreal*>(_v)); break;
        case 9: _t->setDotSize(*reinterpret_cast<qreal*>(_v)); break;
        case 10: _t->setAnimSpeed(*reinterpret_cast<qreal*>(_v)); break;
        case 11: _t->setIntensity(*reinterpret_cast<qreal*>(_v)); break;
        case 12: _t->setColor1(*reinterpret_cast<QColor*>(_v)); break;
        case 13: _t->setColor2(*reinterpret_cast<QColor*>(_v)); break;
        case 14: _t->setColor3(*reinterpret_cast<QColor*>(_v)); break;
        case 15: _t->setBaseColor(*reinterpret_cast<QColor*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *BlobGroup::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *BlobGroup::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9BlobGroupE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int BlobGroup::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 16)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 16;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 16)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 16;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 16;
    }
    return _id;
}

// SIGNAL 0
void BlobGroup::smoothingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void BlobGroup::colorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void BlobGroup::proceduralEnabledChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void BlobGroup::chromeTimeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void BlobGroup::chromeScreenWidthChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void BlobGroup::chromeScreenHeightChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void BlobGroup::chromeOriginXChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void BlobGroup::chromeOriginYChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 7, nullptr);
}

// SIGNAL 8
void BlobGroup::cellSizeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 8, nullptr);
}

// SIGNAL 9
void BlobGroup::dotSizeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 9, nullptr);
}

// SIGNAL 10
void BlobGroup::animSpeedChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 10, nullptr);
}

// SIGNAL 11
void BlobGroup::intensityChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 11, nullptr);
}

// SIGNAL 12
void BlobGroup::color1Changed()
{
    QMetaObject::activate(this, &staticMetaObject, 12, nullptr);
}

// SIGNAL 13
void BlobGroup::color2Changed()
{
    QMetaObject::activate(this, &staticMetaObject, 13, nullptr);
}

// SIGNAL 14
void BlobGroup::color3Changed()
{
    QMetaObject::activate(this, &staticMetaObject, 14, nullptr);
}

// SIGNAL 15
void BlobGroup::baseColorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 15, nullptr);
}
QT_WARNING_POP
