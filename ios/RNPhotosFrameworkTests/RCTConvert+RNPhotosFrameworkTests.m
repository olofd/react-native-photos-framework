#import <XCTest/XCTest.h>
#import <React/RCTConvert.h>
#import "RCTConvert+RNPhotosFramework.h"

@interface RCTConvert_RNPhotosFrameworkTests : XCTestCase

@end

@implementation RCTConvert_RNPhotosFrameworkTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSourceTypesNil {
    int extracted = [RCTConvert PHAssetSourceTypes:nil];
    int nsOptionsExpected = PHAssetSourceTypeNone;
    XCTAssertEqual(extracted, nsOptionsExpected);
}


- (void)testSourceTypesEmpty {
    int extracted = [RCTConvert PHAssetSourceTypes:@[]];
    int nsOptionsExpected = PHAssetSourceTypeNone;
    XCTAssertEqual(extracted, nsOptionsExpected);
}

- (void)testSourceTypesOneType {
    int extracted = [RCTConvert PHAssetSourceTypes:@[@"userLibrary"]];
    int nsOptionsExpected = PHAssetSourceTypeUserLibrary;
    XCTAssertEqual(extracted, nsOptionsExpected);
}

- (void)testSourceTypesMultipleTypes {
    int extracted = [RCTConvert PHAssetSourceTypes:@[@"userLibrary" , @"cloudShared", @"itunesSynced"]];
    int nsOptionsExpected = PHAssetSourceTypeCloudShared | PHAssetSourceTypeUserLibrary | PHAssetSourceTypeiTunesSynced;
    XCTAssertEqual(extracted, nsOptionsExpected);
}


@end
