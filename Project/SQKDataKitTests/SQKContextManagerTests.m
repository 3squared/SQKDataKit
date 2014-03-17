//
//  SQKContextManagerTests.m
//  SQKDataKit
//
//  Created by Luke Stringer on 04/12/2013.
//  Copyright (c) 2013 3Squared. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SQKContextManager.h"

/**
 *  Category that redefines the private internals of SQKContextManager
 *  so we can access the properties necessary for testing.
 */
@interface SQKContextManager (TestVisibility)
@property (nonatomic, strong, readwrite) NSManagedObjectContext* mainContext;
@end

@interface SQKContextManagerTests : XCTestCase
@property (nonatomic, retain) SQKContextManager *contextManager;
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@end

@implementation SQKContextManagerTests

- (void)setUp {
    [super setUp];
    self.managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]];
    self.contextManager = [[SQKContextManager alloc] initWithStoreType:NSInMemoryStoreType managedObjectModel:self.managedObjectModel];
}


#pragma mark - Helpers

- (id)mockMainContextWithStubbedHasChangesReturnValue:(BOOL)hasChanges {
    id mock = [OCMockObject mockForClass:[NSManagedObjectContext class]];
    [[[mock stub] andReturnValue:OCMOCK_VALUE(hasChanges)] hasChanges];
    return mock;
}

#pragma mark - Initialisation

- (void)testInitialisesWithAStoreTypeAndMangedObjectModel {
    self.contextManager = [[SQKContextManager alloc] initWithStoreType:NSInMemoryStoreType managedObjectModel:self.managedObjectModel];
    XCTAssertNotNil(self.contextManager, @"");
    XCTAssertEqualObjects(self.contextManager.storeType, NSInMemoryStoreType, @"");
    XCTAssertEqualObjects(self.contextManager.managedObjectModel, self.managedObjectModel, @"");
}

- (void)testReturnsNilWithNoStoreType {
    self.contextManager = [[SQKContextManager alloc] initWithStoreType:nil managedObjectModel:self.managedObjectModel];
    XCTAssertNil(self.contextManager, @"");
}

- (void)testReturnsNilWithNoManagedObjectModel {
    self.contextManager = [[SQKContextManager alloc] initWithStoreType:NSInMemoryStoreType managedObjectModel:nil];
    XCTAssertNil(self.contextManager, @"");
}

- (void)testReturnsNilWhenUsingIncorrectStoreTypeString {
    self.contextManager = [[SQKContextManager alloc] initWithStoreType:@"unsupported" managedObjectModel:self.managedObjectModel];
    XCTAssertNil(self.contextManager, @"");
}

#pragma mark - Contexts

- (void)testProvidesMainContext {
    XCTAssertNotNil([self.contextManager mainContext], @"");
}

- (void)testProvidesSameMainContext {
    NSManagedObjectContext *firstContext = [self.contextManager mainContext];
    NSManagedObjectContext *secondContext = [self.contextManager mainContext];
    XCTAssertEqualObjects(firstContext, secondContext, @"");
}

- (void)testProvidesANewPrivateContext {
    NSManagedObjectContext *privateContext = [self.contextManager newPrivateContext];
    XCTAssertNotNil(privateContext, @"");
    XCTAssertEqual((NSInteger)privateContext.concurrencyType, (NSInteger)NSPrivateQueueConcurrencyType, @"");
}

- (void)testMainContextAndPrivateContextUseSamePersistentStoreCoordinator {
    NSManagedObjectContext *mainContext = [self.contextManager mainContext];
    NSManagedObjectContext *privateContext = [self.contextManager newPrivateContext];
    XCTAssertEqualObjects(mainContext.persistentStoreCoordinator, privateContext.persistentStoreCoordinator, @"");
}

- (void)testMainContextHasAStoreCoordinator {
    XCTAssertNotNil([self.contextManager mainContext].persistentStoreCoordinator, @"");
}

- (void)testPrivateContextHasAStoreCoordinator {
    XCTAssertNotNil([self.contextManager newPrivateContext].persistentStoreCoordinator, @"");
}

- (void)testStoreCoordinatorHasASingleStore {
    XCTAssertTrue([self.contextManager mainContext].persistentStoreCoordinator.persistentStores.count == 1, @"");
}

#pragma mark - Saving

- (void)testSavesWhenThereAreChanges {
    id contextWithChanges = [self mockMainContextWithStubbedHasChangesReturnValue:YES];
    self.contextManager.mainContext = contextWithChanges;
    
    [[contextWithChanges expect] save:(NSError * __autoreleasing *)[OCMArg anyPointer]];
    
    NSError *saveError = nil;
    BOOL didSave = [self.contextManager saveMainContext:&saveError];
    
    XCTAssertTrue(didSave, @"");
    [contextWithChanges verify];
}

- (void)testDoesNotSaveWhenThrereAreNoChanges {
    id contextWithoutChanges = [self mockMainContextWithStubbedHasChangesReturnValue:NO];
    self.contextManager.mainContext = contextWithoutChanges;
    
    [[contextWithoutChanges reject] save:(NSError * __autoreleasing *)[OCMArg anyPointer]];

    NSError *saveError = nil;
    BOOL didSave = [self.contextManager saveMainContext:&saveError];
    
    XCTAssertFalse(didSave, @"");
    [contextWithoutChanges verify];
}


@end
