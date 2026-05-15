/****************************************************************************
** Meta object code from reading C++ file 'blobrect.hpp'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../Caelestia/Blobs/blobrect.hpp"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'blobrect.hpp' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.11.0. It"
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
struct qt_meta_tag_ZN8BlobRectE_t {};
} // unnamed namespace

template <> constexpr inline auto BlobRect::qt_create_metaobjectdata<qt_meta_tag_ZN8BlobRectE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "BlobRect",
        "QML.Element",
        "auto",
        "stiffnessChanged",
        "",
        "dampingChanged",
        "deformScaleChanged",
        "excludeChanged",
        "topLeftRadiusChanged",
        "topRightRadiusChanged",
        "bottomLeftRadiusChanged",
        "bottomRightRadiusChanged",
        "stiffness",
        "damping",
        "deformScale",
        "exclude",
        "QQmlListProperty<BlobRect>",
        "topLeftRadius",
        "topRightRadius",
        "bottomLeftRadius",
        "bottomRightRadius"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'stiffnessChanged'
        QtMocHelpers::SignalData<void()>(3, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'dampingChanged'
        QtMocHelpers::SignalData<void()>(5, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'deformScaleChanged'
        QtMocHelpers::SignalData<void()>(6, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'excludeChanged'
        QtMocHelpers::SignalData<void()>(7, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'topLeftRadiusChanged'
        QtMocHelpers::SignalData<void()>(8, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'topRightRadiusChanged'
        QtMocHelpers::SignalData<void()>(9, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'bottomLeftRadiusChanged'
        QtMocHelpers::SignalData<void()>(10, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'bottomRightRadiusChanged'
        QtMocHelpers::SignalData<void()>(11, 4, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'stiffness'
        QtMocHelpers::PropertyData<qreal>(12, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'damping'
        QtMocHelpers::PropertyData<qreal>(13, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        // property 'deformScale'
        QtMocHelpers::PropertyData<qreal>(14, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'exclude'
        QtMocHelpers::PropertyData<QQmlListProperty<BlobRect>>(15, 0x80000000 | 16, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 3),
        // property 'topLeftRadius'
        QtMocHelpers::PropertyData<qreal>(17, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 4),
        // property 'topRightRadius'
        QtMocHelpers::PropertyData<qreal>(18, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 5),
        // property 'bottomLeftRadius'
        QtMocHelpers::PropertyData<qreal>(19, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 6),
        // property 'bottomRightRadius'
        QtMocHelpers::PropertyData<qreal>(20, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 7),
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
    });
    return QtMocHelpers::metaObjectData<BlobRect, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject BlobRect::staticMetaObject = { {
    QMetaObject::SuperData::link<BlobShape::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN8BlobRectE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN8BlobRectE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN8BlobRectE_t>.metaTypes,
    nullptr
} };

void BlobRect::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<BlobRect *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->stiffnessChanged(); break;
        case 1: _t->dampingChanged(); break;
        case 2: _t->deformScaleChanged(); break;
        case 3: _t->excludeChanged(); break;
        case 4: _t->topLeftRadiusChanged(); break;
        case 5: _t->topRightRadiusChanged(); break;
        case 6: _t->bottomLeftRadiusChanged(); break;
        case 7: _t->bottomRightRadiusChanged(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (BlobRect::*)()>(_a, &BlobRect::stiffnessChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobRect::*)()>(_a, &BlobRect::dampingChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobRect::*)()>(_a, &BlobRect::deformScaleChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobRect::*)()>(_a, &BlobRect::excludeChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobRect::*)()>(_a, &BlobRect::topLeftRadiusChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobRect::*)()>(_a, &BlobRect::topRightRadiusChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobRect::*)()>(_a, &BlobRect::bottomLeftRadiusChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobRect::*)()>(_a, &BlobRect::bottomRightRadiusChanged, 7))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<qreal*>(_v) = _t->stiffness(); break;
        case 1: *reinterpret_cast<qreal*>(_v) = _t->damping(); break;
        case 2: *reinterpret_cast<qreal*>(_v) = _t->deformScale(); break;
        case 3: *reinterpret_cast<QQmlListProperty<BlobRect>*>(_v) = _t->exclude(); break;
        case 4: *reinterpret_cast<qreal*>(_v) = _t->topLeftRadius(); break;
        case 5: *reinterpret_cast<qreal*>(_v) = _t->topRightRadius(); break;
        case 6: *reinterpret_cast<qreal*>(_v) = _t->bottomLeftRadius(); break;
        case 7: *reinterpret_cast<qreal*>(_v) = _t->bottomRightRadius(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setStiffness(*reinterpret_cast<qreal*>(_v)); break;
        case 1: _t->setDamping(*reinterpret_cast<qreal*>(_v)); break;
        case 2: _t->setDeformScale(*reinterpret_cast<qreal*>(_v)); break;
        case 4: _t->setTopLeftRadius(*reinterpret_cast<qreal*>(_v)); break;
        case 5: _t->setTopRightRadius(*reinterpret_cast<qreal*>(_v)); break;
        case 6: _t->setBottomLeftRadius(*reinterpret_cast<qreal*>(_v)); break;
        case 7: _t->setBottomRightRadius(*reinterpret_cast<qreal*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *BlobRect::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *BlobRect::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN8BlobRectE_t>.strings))
        return static_cast<void*>(this);
    return BlobShape::qt_metacast(_clname);
}

int BlobRect::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = BlobShape::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 8)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 8;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 8)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 8;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 8;
    }
    return _id;
}

// SIGNAL 0
void BlobRect::stiffnessChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void BlobRect::dampingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void BlobRect::deformScaleChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void BlobRect::excludeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void BlobRect::topLeftRadiusChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void BlobRect::topRightRadiusChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void BlobRect::bottomLeftRadiusChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void BlobRect::bottomRightRadiusChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 7, nullptr);
}
QT_WARNING_POP
