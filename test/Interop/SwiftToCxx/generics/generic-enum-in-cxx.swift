// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend %s -typecheck -module-name Generics -clang-header-expose-public-decls -emit-clang-header-path %t/generics.h
// RUN: %FileCheck %s < %t/generics.h
// RUN: %check-generic-interop-cxx-header-in-clang(%t/generics.h -Wno-reserved-identifier)

// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend %s -enable-library-evolution -typecheck -module-name Generics -clang-header-expose-public-decls -emit-clang-header-path %t/generics.h
// RUN: %FileCheck %s < %t/generics.h
// RUN: %check-generic-interop-cxx-header-in-clang(%t/generics.h -Wno-reserved-identifier)

// FIXME: remove the need for -Wno-reserved-identifier

public class TracksDeinit {
    init() {
        print("init-TracksDeinit")
    }
    deinit {
        print("destroy-TracksDeinit")
    }
}

public func constructTracksDeinit() -> TracksDeinit {
    return TracksDeinit()
}

@frozen
public struct StructForEnum {
    let x: TracksDeinit

    public init() {
        x = TracksDeinit()
    }
}

@frozen public enum GenericOpt<T> {
    case none
    case some(T)

    public func method() {
        let copyOfSelf = self
        print("GenericOpt<T>::testme::\(copyOfSelf);")
    }

    public mutating func reset() {
        self = .none
    }

    public func genericMethod<T>(_ x: T) -> T {
        print("GenericOpt<T>::genericMethod<T>::\(self),\(x);")
        return x
    }

    public var computedProp: Int {
        return 42
    }
}

public func makeGenericOpt<T>(_ x: T) -> GenericOpt<T> {
    return .some(x)
}

public func makeConcreteOpt(_ x: UInt16) -> GenericOpt<UInt16> {
    return GenericOpt<UInt16>.some(x)
}

public func takeGenericOpt<T>(_ x: GenericOpt<T>) {
    print(x)
}

public func takeConcreteOpt(_ x: GenericOpt<UInt16>) {
    print("CONCRETE opt:", x, ";")
}

public func inoutGenericOpt<T>(_ x: inout GenericOpt<T>, _ y: T) {
    switch (x) {
    case .some:
        x = .none
    case .none:
        x = .some(y)
    }
}

public func inoutConcreteOpt(_ x: inout GenericOpt<UInt16>) {
    switch (x) {
    case .some(let x_):
        x = .some(x_ * 3)
    case .none:
        break
    }
}

// CHECK: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT: class _impl_GenericOpt;

// CHECK: SWIFT_EXTERN swift::_impl::MetadataResponseTy $s8Generics10GenericOptOMa(swift::_impl::MetadataRequestTy, void * _Nonnull) SWIFT_NOEXCEPT SWIFT_CALL;

// CHECK: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT: class GenericOpt final {
// CHECK-NEXT: public:
// CHECK-NEXT: inline ~GenericOpt() {
// CHECK-NEXT:   auto metadata = _impl::$s8Generics10GenericOptOMa(0, swift::TypeMetadataTrait<T_0_0>::getTypeMetadata());
// CHECK-NEXT:   auto *vwTableAddr = reinterpret_cast<swift::_impl::ValueWitnessTable **>(metadata._0) - 1;
// CHECK-NEXT: #ifdef __arm64e__
// CHECK-NEXT:   auto *vwTable = reinterpret_cast<swift::_impl::ValueWitnessTable *>(ptrauth_auth_data(reinterpret_cast<void *>(*vwTableAddr), ptrauth_key_process_independent_data, ptrauth_blend_discriminator(vwTableAddr, 11839)));
// CHECK-NEXT: #else
// CHECK-NEXT:   auto *vwTable = *vwTableAddr;
// CHECK-NEXT: #endif
// CHECK-NEXT:   vwTable->destroy(_getOpaquePointer(), metadata._0);
// CHECK-NEXT: }

// CHECK: enum class cases {
// CHECK-NEXT:  some,
// CHECK-NEXT:  none
// CHECK-NEXT: };

// CHECK: inline operator cases() const {
// CHECK-NEXT:   switch (_getEnumTag()) {
// CHECK-NEXT:     case 0: return cases::some;
// CHECK-NEXT:     case 1: return cases::none;
// CHECK-NEXT:     default: abort();
// CHECK-NEXT:   }
// CHECK-NEXT: }

// CHECK: inline void method() const;
// CHECK-NEXT: inline void reset();
// CHECK-NEXT: template<class T_1_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_1_0>
// CHECK-NEXT: inline T_1_0 genericMethod(const T_1_0& x) const;
// CHECK-NEXT: inline swift::Int getComputedProp() const;


// CHECK: inline void inoutConcreteOpt(GenericOpt<uint16_t>& x) noexcept {
// CHECK-NEXT:   return _impl::$s8Generics16inoutConcreteOptyyAA07GenericD0Oys6UInt16VGzF(_impl::_impl_GenericOpt<uint16_t>::getOpaquePointer(x));
// CHECK-NEXT: }


// CHECK: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT: inline void inoutGenericOpt(GenericOpt<T_0_0>& x, const T_0_0& y) noexcept {
// CHECK-NEXT:   return _impl::$s8Generics15inoutGenericOptyyAA0cD0OyxGz_xtlF(_impl::_impl_GenericOpt<T_0_0>::getOpaquePointer(x), swift::_impl::getOpaquePointer(y), swift::TypeMetadataTrait<T_0_0>::getTypeMetadata());
// CHECK-NEXT: }


// CHECK: inline GenericOpt<uint16_t> makeConcreteOpt(uint16_t x) noexcept SWIFT_WARN_UNUSED_RESULT {
// CHECK-NEXT:   return _impl::_impl_GenericOpt<uint16_t>::returnNewValue([&](char * _Nonnull result) {
// CHECK-NEXT:     _impl::swift_interop_returnDirect_Generics_uint32_t_0_4(result, _impl::$s8Generics15makeConcreteOptyAA07GenericD0Oys6UInt16VGAFF(x));
// CHECK-NEXT:   });
// CHECK-NEXT: }


// CHECK: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT: inline GenericOpt<T_0_0> makeGenericOpt(const T_0_0& x) noexcept SWIFT_WARN_UNUSED_RESULT {
// CHECK-NEXT:   return _impl::_impl_GenericOpt<T_0_0>::returnNewValue([&](char * _Nonnull result) {
// CHECK-NEXT:     _impl::$s8Generics14makeGenericOptyAA0cD0OyxGxlF(result, swift::_impl::getOpaquePointer(x), swift::TypeMetadataTrait<T_0_0>::getTypeMetadata());
// CHECK-NEXT:   });
// CHECK-NEXT: }


// CHECK: inline void takeConcreteOpt(const GenericOpt<uint16_t>& x) noexcept {
// CHECK-NEXT:   return _impl::$s8Generics15takeConcreteOptyyAA07GenericD0Oys6UInt16VGF(_impl::swift_interop_passDirect_Generics_uint32_t_0_4(_impl::_impl_GenericOpt<uint16_t>::getOpaquePointer(x)));
// CHECK-NEXT: }


// CHECK: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT: inline void takeGenericOpt(const GenericOpt<T_0_0>& x) noexcept {
// CHECK-NEXT:  return _impl::$s8Generics14takeGenericOptyyAA0cD0OyxGlF(_impl::_impl_GenericOpt<T_0_0>::getOpaquePointer(x), swift::TypeMetadataTrait<T_0_0>::getTypeMetadata());
// CHECK-NEXT: }

// CHECK: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT:   inline bool GenericOpt<T_0_0>::isSome() const {
// CHECK-NEXT:     return *this == GenericOpt<T_0_0>::some;
// CHECK-NEXT:   }
// CHECK-NEXT:   template<class T_0_0>
// CHECK-NEXT:   requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT:     inline T_0_0 GenericOpt<T_0_0>::getSome() const {
// CHECK-NEXT:       if (!isSome()) abort();
// CHECK-NEXT:       alignas(GenericOpt) unsigned char buffer[sizeof(GenericOpt)];
// CHECK-NEXT:       auto *thisCopy = new(buffer) GenericOpt(*this);
// CHECK-NEXT:       char * _Nonnull payloadFromDestruction = thisCopy->_destructiveProjectEnumData();
// CHECK-NEXT:     if constexpr (std::is_base_of<::swift::_impl::RefCountedClass, T_0_0>::value) {
// CHECK-NEXT:     void *returnValue;
// CHECK-NEXT:     returnValue = *reinterpret_cast<void **>(payloadFromDestruction);
// CHECK-NEXT:     return ::swift::_impl::implClassFor<T_0_0>::type::makeRetained(returnValue);
// CHECK-NEXT:     } else if constexpr (::swift::_impl::isValueType<T_0_0>) {
// CHECK-NEXT:     return ::swift::_impl::implClassFor<T_0_0>::type::returnNewValue([&](void * _Nonnull returnValue) {
// CHECK-NEXT:    return ::swift::_impl::implClassFor<T_0_0>::type::initializeWithTake(reinterpret_cast<char * _Nonnull>(returnValue), payloadFromDestruction);
// CHECK-NEXT:     });
// CHECK-NEXT:     } else if constexpr (::swift::_impl::isSwiftBridgedCxxRecord<T_0_0>) {
// CHECK-NEXT:   abort();
// CHECK-NEXT:     } else {
// CHECK-NEXT:     T_0_0 returnValue;
// CHECK-NEXT:   memcpy(&returnValue, payloadFromDestruction, sizeof(returnValue));
// CHECK-NEXT:     return returnValue;
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT:   inline bool GenericOpt<T_0_0>::isNone() const {
// CHECK-NEXT:     return *this == GenericOpt<T_0_0>::none;
// CHECK-NEXT:   }

// CHECK: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT: inline void GenericOpt<T_0_0>::method() const {
// CHECK-NEXT: return _impl::$s8Generics10GenericOptO6methodyyF(swift::TypeMetadataTrait<GenericOpt<T_0_0>>::getTypeMetadata(), _getOpaquePointer());
// CHECK-NEXT: }

// CHECK: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT: void GenericOpt<T_0_0>::reset()

// CHECK: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT: template<class T_1_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_1_0>
// CHECK-NEXT: inline T_1_0 GenericOpt<T_0_0>::genericMethod(const T_1_0& x) const {

// CHECK: template<class T_0_0>
// CHECK-NEXT: requires swift::isUsableInGenericContext<T_0_0>
// CHECK-NEXT: inline swift::Int GenericOpt<T_0_0>::getComputedProp() const {
// CHECK-NEXT: return _impl::$s8Generics10GenericOptO12computedPropSivg(swift::TypeMetadataTrait<GenericOpt<T_0_0>>::getTypeMetadata(), _getOpaquePointer());
// CHECK-NEXT: }
