#import "godotx_att.h"
#import <Foundation/Foundation.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>

GodotxATT *GodotxATT::instance = nullptr;

GodotxATT *GodotxATT::get_singleton() {
    return instance;
}

GodotxATT::GodotxATT() {
    if (instance != nullptr) {
        ERR_FAIL_MSG("Instance already exists");
    }
    instance = this;
}

GodotxATT::~GodotxATT() {
    if (instance == this) {
        instance = nullptr;
    }
}

void GodotxATT::_bind_methods() {
    ADD_SIGNAL(MethodInfo("permission_result", PropertyInfo(Variant::DICTIONARY, "data")));

    ClassDB::bind_method(D_METHOD("request_permission"), &GodotxATT::request_permission);
    ClassDB::bind_method(D_METHOD("get_status"), &GodotxATT::get_status);
    ClassDB::bind_method(D_METHOD("get_status_string"), &GodotxATT::get_status_string);
}

void GodotxATT::request_permission() {
    if (@available(iOS 14.0, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                Dictionary d;
                d["status"] = (int)status;

                switch (status) {
                    case ATTrackingManagerAuthorizationStatusNotDetermined:
                        d["status_string"] = "not_determined";
                        break;
                    case ATTrackingManagerAuthorizationStatusRestricted:
                        d["status_string"] = "restricted";
                        break;
                    case ATTrackingManagerAuthorizationStatusDenied:
                        d["status_string"] = "denied";
                        break;
                    case ATTrackingManagerAuthorizationStatusAuthorized:
                        d["status_string"] = "authorized";
                        break;
                }

                emit_signal("permission_result", d);
            });
        }];
    } else {
        // ios < 14.0: tracking allowed by default
        dispatch_async(dispatch_get_main_queue(), ^{
            Dictionary d;
            d["status"] = 3;
            d["status_string"] = "authorized";
            emit_signal("permission_result", d);
        });
    }
}

int GodotxATT::get_status() {
    if (@available(iOS 14.0, *)) {
        return (int)[ATTrackingManager trackingAuthorizationStatus];
    }
    // ios < 14.0: tracking allowed by default
    return 3;
}

String GodotxATT::get_status_string() {
    if (@available(iOS 14.0, *)) {
        ATTrackingManagerAuthorizationStatus status = [ATTrackingManager trackingAuthorizationStatus];

        switch (status) {
            case ATTrackingManagerAuthorizationStatusNotDetermined:
                return "not_determined";
            case ATTrackingManagerAuthorizationStatusRestricted:
                return "restricted";
            case ATTrackingManagerAuthorizationStatusDenied:
                return "denied";
            case ATTrackingManagerAuthorizationStatusAuthorized:
                return "authorized";
        }
    }
    // ios < 14.0: tracking allowed by default
    return "authorized";
}
