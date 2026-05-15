/****************************************************************************
** Meta object code from reading C++ file 'blobinvertedrect.hpp'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../Caelestia/Blobs/blobinvertedrect.hpp"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'blobinvertedrect.hpp' doesn't include <QObject>."
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
struct qt_meta_tag_ZN16BlobInvertedRectE_t {};
} // unnamed namespace

template <> constexpr inline auto BlobInvertedRect::qt_create_metaobjectdata<qt_meta_tag_ZN16BlobInvertedRectE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "BlobInvertedRect",
        "QML.Element",
        "auto",
        "borderLeftChanged",
        "",
        "borderRightChanged",
        "borderTopChanged",
        "borderBottomChanged",
        "borderLeft",
        "borderRight",
        "borderTop",
        "borderBottom"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'borderLeftChanged'
        QtMocHelpers::SignalData<void()>(3, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'borderRightChanged'
        QtMocHelpers::SignalData<void()>(5, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'borderTopChanged'
        QtMocHelpers::SignalData<void()>(6, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'borderBottomChanged'
        QtMocHelpers::SignalData<void()>(7, 4, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'borderLeft'
        QtMocHelpers::PropertyData<qreal>(8, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'borderRight'
        QtMocHelpers::PropertyData<qreal>(9, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        // property 'borderTop'
        QtMocHelpers::PropertyData<qreal>(10, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'borderBottom'
        QtMocHelpers::PropertyData<qreal>(11, QMetaType::QReal, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 3),
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
    });
    return QtMocHelpers::metaObjectData<BlobInvertedRect, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject BlobInvertedRect::staticMetaObject = { {
    QMetaObject::SuperData::link<BlobShape::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16BlobInvertedRectE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16BlobInvertedRectE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN16BlobInvertedRectE_t>.metaTypes,
    nullptr
} };

void BlobInvertedRect::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<BlobInvertedRect *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->borderLeftChanged(); break;
        case 1: _t->borderRightChanged(); break;
        case 2: _t->borderTopChanged(); break;
        case 3: _t->borderBottomChanged(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (BlobInvertedRect::*)()>(_a, &BlobInvertedRect::borderLeftChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobInvertedRect::*)()>(_a, &BlobInvertedRect::borderRightChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobInvertedRect::*)()>(_a, &BlobInvertedRect::borderTopChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (BlobInvertedRect::*)()>(_a, &BlobInvertedRect::borderBottomChanged, 3))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<qreal*>(_v) = _t->borderLeft(); break;
        case 1: *reinterpret_cast<qreal*>(_v) = _t->borderRight(); break;
        case 2: *reinterpret_cast<qreal*>(_v) = _t->borderTop(); break;
        case 3: *reinterpret_cast<qreal*>(_v) = _t->borderBottom(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setBorderLeft(*reinterpret_cast<qreal*>(_v)); break;
        case 1: _t->setBorderRight(*reinterpret_cast<qreal*>(_v)); break;
        case 2: _t->setBorderTop(*reinterpret_cast<qreal*>(_v)); break;
        case 3: _t->setBorderBottom(*reinterpret_cast<qreal*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *BlobInvertedRect::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *BlobInvertedRect::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16BlobInvertedRectE_t>.strings))
        return static_cast<void*>(this);
    return BlobShape::qt_metacast(_clname);
}

int BlobInvertedRect::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = BlobShape::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 4)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 4)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 4;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    }
    return _id;
}

// SIGNAL 0
void BlobInvertedRect::borderLeftChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void BlobInvertedRect::borderRightChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void BlobInvertedRect::borderTopChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void BlobInvertedRect::borderBottomChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}
QT_WARNING_POP
