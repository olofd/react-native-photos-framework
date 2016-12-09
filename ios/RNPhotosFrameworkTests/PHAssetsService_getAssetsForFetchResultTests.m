#pragma clang diagnostic ignored "-Wincompatible-pointer-types"

#import <XCTest/XCTest.h>
#import "PHAssetsService.h"

@interface PHAssetsServicegetAssetsForFetchResultTests : XCTestCase
@end

@implementation PHAssetsServicegetAssetsForFetchResultTests
NSMutableArray *arrayWithFakeAssets;
NSMutableArray *scenarioAssets;


- (void)setUp {
    arrayWithFakeAssets = [NSMutableArray new];
    for(int i = 0; i < 200;i++){
        [arrayWithFakeAssets addObject:@(i)];
    }
    
    scenarioAssets = [NSMutableArray new];
    [scenarioAssets addObject:@(2012)];
    [scenarioAssets addObject:@(2013)];
    [scenarioAssets addObject:@(2014)];
    [scenarioAssets addObject:@(2015)];
    [scenarioAssets addObject:@(2016)];

    [super setUp];
}

- (void)tearDown {
    arrayWithFakeAssets = nil;
    scenarioAssets = nil;
    [super tearDown];
}

- (void)testShouldReturnEqualAmountOfAssets {
    NSArray *resultYesYes = [PHAssetsService getAssetsForFetchResult:arrayWithFakeAssets startIndex:5 endIndex:15 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:YES];
    [self setUp];
    NSArray *resultYesNo = [PHAssetsService getAssetsForFetchResult:arrayWithFakeAssets startIndex:5 endIndex:15 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:NO];
    [self setUp];
    NSArray *resultNoYes = [PHAssetsService getAssetsForFetchResult:arrayWithFakeAssets startIndex:5 endIndex:15 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:NO];
    [self setUp];
    NSArray *resultNoNo = [PHAssetsService getAssetsForFetchResult:arrayWithFakeAssets startIndex:5 endIndex:15 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:NO];
    XCTAssertTrue(resultYesYes.count == 10);
    XCTAssertTrue(resultYesNo.count == 10);
    XCTAssertTrue(resultNoYes.count == 10);
    XCTAssertTrue(resultNoNo.count == 10);
}

//Testing scenarios from : https://github.com/olofd/react-native-photos-framework/pull/11#issuecomment-264324873
-(void) testOrderScenarioOne {
    NSArray <NSNumber *> *result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:0 endIndex:2 assetDisplayStartToEnd:NO andAssetDisplayBottomUp:YES];
    
    XCTAssertEqual(result.count, 3);
    XCTAssertEqual([result[0] intValue], 2016);
    XCTAssertEqual([result[1] intValue], 2015);
    XCTAssertEqual([result[2] intValue], 2014);
    //scrolling down will load
    result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:3 endIndex:5 assetDisplayStartToEnd:NO andAssetDisplayBottomUp:YES];
    XCTAssertEqual(result.count, 2);
    XCTAssertEqual([result[0] intValue], 2013);
    XCTAssertEqual([result[1] intValue], 2012);
}

-(void) testOrderScenarioTwo {
    NSArray <NSNumber *> *result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:0 endIndex:2 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:YES];
    
    XCTAssertEqual(result.count, 3);
    XCTAssertEqual([result[0] intValue], 2012);
    XCTAssertEqual([result[1] intValue], 2013);
    XCTAssertEqual([result[2] intValue], 2014);
    //scrolling down will load
    result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:3 endIndex:5 assetDisplayStartToEnd:NO andAssetDisplayBottomUp:YES];
    XCTAssertEqual(result.count, 2);
    XCTAssertEqual([result[0] intValue], 2015);
    XCTAssertEqual([result[1] intValue], 2016);
}

-(void) testOrderScenarioThree {
    NSArray <NSNumber *> *result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:0 endIndex:2 assetDisplayStartToEnd:NO andAssetDisplayBottomUp:NO];
    
    XCTAssertEqual(result.count, 3);
    XCTAssertEqual([result[0] intValue], 2012);
    XCTAssertEqual([result[1] intValue], 2013);
    XCTAssertEqual([result[2] intValue], 2014);
    //scrolling up will load
    result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:3 endIndex:5 assetDisplayStartToEnd:NO andAssetDisplayBottomUp:YES];
    XCTAssertEqual(result.count, 2);
    XCTAssertEqual([result[0] intValue], 2015);
    XCTAssertEqual([result[1] intValue], 2016);
}

-(void) testOrderScenarioFour {
    NSArray <NSNumber *> *result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:0 endIndex:2 assetDisplayStartToEnd:YES andAssetDisplayBottomUp:NO];
    
    XCTAssertEqual(result.count, 3);
    XCTAssertEqual([result[0] intValue], 2016);
    XCTAssertEqual([result[1] intValue], 2015);
    XCTAssertEqual([result[2] intValue], 2014);
    //scrolling up will load
    result = [PHAssetsService getAssetsForFetchResult:scenarioAssets startIndex:3 endIndex:5 assetDisplayStartToEnd:NO andAssetDisplayBottomUp:YES];
    XCTAssertEqual(result.count, 2);
    XCTAssertEqual([result[0] intValue], 2013);
    XCTAssertEqual([result[1] intValue], 2012);
}

@end
