// Generated by Apple Swift version 4.0.2 (swiftlang-900.0.69.2 clang-900.0.38)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgcc-compat"

#if !defined(__has_include)
# define __has_include(x) 0
#endif
#if !defined(__has_attribute)
# define __has_attribute(x) 0
#endif
#if !defined(__has_feature)
# define __has_feature(x) 0
#endif
#if !defined(__has_warning)
# define __has_warning(x) 0
#endif

#if __has_attribute(external_source_symbol)
# define SWIFT_STRINGIFY(str) #str
# define SWIFT_MODULE_NAMESPACE_PUSH(module_name) _Pragma(SWIFT_STRINGIFY(clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in=module_name, generated_declaration))), apply_to=any(function, enum, objc_interface, objc_category, objc_protocol))))
# define SWIFT_MODULE_NAMESPACE_POP _Pragma("clang attribute pop")
#else
# define SWIFT_MODULE_NAMESPACE_PUSH(module_name)
# define SWIFT_MODULE_NAMESPACE_POP
#endif

#if __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <objc/NSObject.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus) || __cplusplus < 201103L
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...)
# endif
#endif

#if __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if __has_attribute(objc_method_family)
# define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
#else
# define SWIFT_METHOD_FAMILY(X)
#endif
#if __has_attribute(noescape)
# define SWIFT_NOESCAPE __attribute__((noescape))
#else
# define SWIFT_NOESCAPE
#endif
#if __has_attribute(warn_unused_result)
# define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
# define SWIFT_WARN_UNUSED_RESULT
#endif
#if __has_attribute(noreturn)
# define SWIFT_NORETURN __attribute__((noreturn))
#else
# define SWIFT_NORETURN
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM_ATTR)
# if defined(__has_attribute) && __has_attribute(enum_extensibility)
#  define SWIFT_ENUM_ATTR __attribute__((enum_extensibility(open)))
# else
#  define SWIFT_ENUM_ATTR
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name) enum _name : _type _name; enum SWIFT_ENUM_ATTR SWIFT_ENUM_EXTRA _name : _type
# if __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_ATTR SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) SWIFT_ENUM(_type, _name)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if __has_feature(attribute_diagnose_if_objc)
# define SWIFT_DEPRECATED_OBJC(Msg) __attribute__((diagnose_if(1, Msg, "warning")))
#else
# define SWIFT_DEPRECATED_OBJC(Msg) SWIFT_DEPRECATED_MSG(Msg)
#endif
#if __has_feature(modules)
@import ObjectiveC;
@import CoreBluetooth;
@import Foundation;
@import CoreLocation;
@import UIKit;
#endif

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
#if __has_warning("-Wpragma-clang-attribute")
# pragma clang diagnostic ignored "-Wpragma-clang-attribute"
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wnullability"

SWIFT_MODULE_NAMESPACE_PUSH("Trckr")
@protocol BeaconDelegate;

/// A client for monitoring beacon regions.
/// Beacons are small devices that advertize their location by emitting a BLE (Bluetooth Low Energy) signal in 2.4Ghz frequency range.
/// Beacons can be attached to stationary or moving objects which can then be detected and identified by Trckr.
/// The <code>Beacon</code> class provides methods for adding and removing beacon regions.
/// You add a new beacon region with <code>Beacon.addBeacon(proximityUUID:notify:identifier:)</code>. When that region is  crossed - either exiting or entering that region - <code>Beacon</code> client will call <code>TrckrDelegate.didCross(region:type:withinSchedule:)</code> method.
SWIFT_CLASS("_TtC5Trckr6Beacon")
@interface Beacon : NSObject
@property (nonatomic, strong) id <BeaconDelegate> _Nullable delegate;
/// This is the one and only Beacon client instance
SWIFT_CLASS_PROPERTY(@property (nonatomic, class, readonly, strong) Beacon * _Nonnull shared;)
+ (Beacon * _Nonnull)shared SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

@class CBCentralManager;
@class CBPeripheral;
@class NSNumber;

@interface Beacon (SWIFT_EXTENSION(Trckr)) <CBCentralManagerDelegate>
- (void)centralManagerDidUpdateState:(CBCentralManager * _Nonnull)central;
- (void)centralManager:(CBCentralManager * _Nonnull)central didDiscoverPeripheral:(CBPeripheral * _Nonnull)peripheral advertisementData:(NSDictionary<NSString *, id> * _Nonnull)advertisementData RSSI:(NSNumber * _Nonnull)RSSI;
- (void)centralManager:(CBCentralManager * _Nonnull)central didConnectPeripheral:(CBPeripheral * _Nonnull)peripheral;
@end

@class CBService;
@class CBCharacteristic;

@interface Beacon (SWIFT_EXTENSION(Trckr)) <CBPeripheralDelegate>
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverServices:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverCharacteristicsForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
@end


SWIFT_PROTOCOL("_TtP5Trckr14BeaconDelegate_")
@protocol BeaconDelegate
@optional
- (void)didPowerOn;
/// found a CBPeripheral
- (void)didDiscoverWithPeripheral:(CBPeripheral * _Nonnull)peripheral;
- (void)didFindWithPeripheral:(CBPeripheral * _Nonnull)peripheral uuid:(NSUUID * _Nonnull)uuid;
- (void)didUpdateWithPeripheral:(CBPeripheral * _Nonnull)peripheral newUUID:(NSUUID * _Nonnull)newUUID;
- (void)didFailToFindUUIDWithPeripheral:(CBPeripheral * _Nonnull)peripheral;
- (void)didFailToUpdateUUIDWithPeripheral:(CBPeripheral * _Nonnull)peripheral;
@end




/// A client for monitoring circular (geographic) regions.
/// A geographical region is an area defined by a circle of a specified radius around a known point on the Earth’s surface.
/// <code>Geofence</code> class is used internally by <code>Trckr</code> for monitoring when the user resumes movement. While the user is moving, <code>Trckr</code> receives continuous location updates from CoreLocation.
/// When the user stops moving, a geofence region is added with <code>Geofence.RegionId</code> as its identifier and an <code>.Exit</code> trigger. When the user exists the geofenced region, continuous location updates are resumed.
/// In iOS, regions associated with your app are tracked at all times, including when the app isn’t running, and are very power efficient since the hardware required to monitor them is already used by other services - WiFi and Cellular signal.
/// Monitoring geofence regions allows <code>Trckr</code> to track the user’s location even when your app isn’t running.
/// You should not use <code>Geofence</code> class directly.
SWIFT_CLASS("_TtC5Trckr8Geofence")
@interface Geofence : NSObject
/// The one and only Geofence client instance.
SWIFT_CLASS_PROPERTY(@property (nonatomic, class, readonly, strong) Geofence * _Nonnull shared;)
+ (Geofence * _Nonnull)shared SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

/// The type of trigger for a monitroed region
typedef SWIFT_ENUM(NSInteger, RegionTriggerType) {
/// Monitor (and notify) when the user <em>enters</em> the region
  RegionTriggerTypeEntry = 0,
/// Monitor (and notify) when the user <em>exits</em> the region
  RegionTriggerTypeExit = 1,
/// Monitor both entry and exit
  RegionTriggerTypeAll = 2,
};


/// Trckr Internal logging facility.
/// To enable Trckr logs, call <code>Log.start()</code>.
/// By default, Trckr logs to the console and to a file. This can be disabled with <code>enableConsoleLog</code> and <code>enableFileLog</code> respectively. The current log file can be accessed with <code>logFileName</code>.
/// Log files are capped at 1MB and are rotated. When a log file is rotated, it is renamed and saved as archive. You can get the archived log file path via <code>didRotateLogFile</code> closure.
SWIFT_CLASS("_TtC5Trckr3Log")
@interface Log : NSObject
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

@protocol TrckrDelegate;

/// Provides location tracking using a combination of:
/// <ul>
///   <li>
///     Continuous location updates (while the user is moving)
///   </li>
///   <li>
///     Significant location changes (to sustain background operation)
///   </li>
///   <li>
///     Region monitoring, using <code>Geofence</code> (when the user is stationary)
///   </li>
///   <li>
///     <code>Beacon</code> region monitoring (e.g. detecting vehicle used)
///   </li>
/// </ul>
/// Usage:
/// \code
///     // start tracking
///     Trckr.sharedInstance.trackingEnabled = true
///
///     // stop tracking
///     Trckr.sharedInstance.trackingEnabled = false
///
/// \endcodeWhen using Trckr, you must add the following entries to your app’s <em>info.plist</em>:
/// <ul>
///   <li>
///     NSMotionUsageDescription
///   </li>
///   <li>
///     NSLocationAlwaysAndWhenInUseUsageDescription
///   </li>
///   <li>
///     NSLocationAlwaysUsageDescription
///   </li>
///   <li>
///     NSLocationWhenInUseUsageDescription
///   </li>
///   <li>
///     UIBackgroundModes: location
///   </li>
/// </ul>
SWIFT_CLASS("_TtC5Trckr5Trckr")
@interface Trckr : NSObject <CLLocationManagerDelegate>
/// This is the one and only Trckr instance
SWIFT_CLASS_PROPERTY(@property (nonatomic, class, readonly, strong) Trckr * _Nonnull shared;)
+ (Trckr * _Nonnull)shared SWIFT_WARN_UNUSED_RESULT;
/// location updates and other events are delivered to this delegate.
@property (nonatomic, strong) id <TrckrDelegate> _Nullable delegate;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end





@class CLLocationManager;
@class CLRegion;

@interface Trckr (SWIFT_EXTENSION(Trckr))
/// :nodoc:
/// This method updates TrckrDelegate.didChangeAuthorization()`
- (void)locationManager:(CLLocationManager * _Nonnull)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
/// :nodoc:
/// This method stores new locations internally and updates <code>TrckrDelegate.didUpdateLocations()</code>
- (void)locationManager:(CLLocationManager * _Nonnull)manager didUpdateLocations:(NSArray<CLLocation *> * _Nonnull)locations;
/// :nodoc:
- (void)locationManager:(CLLocationManager * _Nonnull)manager didExitRegion:(CLRegion * _Nonnull)region;
/// :nodoc:
- (void)locationManager:(CLLocationManager * _Nonnull)manager didEnterRegion:(CLRegion * _Nonnull)region;
/// :nodoc:
- (void)locationManager:(CLLocationManager * _Nonnull)manager monitoringDidFailForRegion:(CLRegion * _Nullable)region withError:(NSError * _Nonnull)error;
/// :nodoc:
- (void)locationManager:(CLLocationManager * _Nonnull)manager didStartMonitoringForRegion:(CLRegion * _Nonnull)region;
/// :nodoc:
- (void)locationManager:(CLLocationManager * _Nonnull)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion * _Nonnull)region;
@end




/// This protocol defines the methods you should use in order to receive events and location updates from <code>Trckr</code>.
SWIFT_PROTOCOL("_TtP5Trckr13TrckrDelegate_")
@protocol TrckrDelegate
@optional
/// Tells the delegate that continuous location tracking started. This happens when the user starts moving.
- (void)didStartTracking;
/// Tells the delegate that continuous location tracking stopped. This happens when the user stops moving.
- (void)didStopTracking;
/// Tells the delegate that new location data is available.
/// \param locations the new locations received and successfully filtered. Trckr uses <code>DesiredAccuracy</code> to filter new locations and discards locations with low accuracy.
///
- (void)didUpdateLocations:(NSArray<CLLocation *> * _Nonnull)locations;
/// Notifies the delegate when a region is crossed.
/// The crossed region can be identified by the <code>region.identifier</code> which is either <code>Geofence.RegionId</code> or <code>Beacon.RegionId</code>.
/// <code>Geofence</code> regions are automatically maintained by Trckr and you should not add or remove them yourself. Geofences are used as a trigger for (potentially) resuming continuous location tracking when the user starts moving.
/// <code>Beacon</code> regions must be explicitely added by your app if you’d like to monitor beacons.
/// This method is the first delegate method called when the user starts moving. Following this call, <code>didStartTracking</code> may be called as well.
/// \param region the region crossed
///
/// \param type one of <code>Geofence.GeofenceType</code>, i.e. .Exit or .Entry. Note that for Geofence crossing only .Exit is supported.
///
/// \param withinSchedule <em>false</em> if the current time is <em>not</em> within the scheduled tracking time. <em>treu</em> if the current time is within the schedule, or if no tracking schedule was set.
///
- (void)didCrossWithRegion:(CLRegion * _Nonnull)region type:(enum RegionTriggerType)type withinSchedule:(BOOL)withinSchedule;
/// Asks the delegate whether tracking should occur outside the tracking schedule.
/// This method is called only when <code>trackingSchedule</code> is set on Trckr.
- (BOOL)shouldTrackOutsideSchedule SWIFT_WARN_UNUSED_RESULT;
/// Notifies the delegate when the authorization status changed
- (void)didChangeAuthorizationWithStatus:(CLAuthorizationStatus)status;
@end



SWIFT_MODULE_NAMESPACE_POP
#pragma clang diagnostic pop
