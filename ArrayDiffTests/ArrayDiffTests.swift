//
//  ArrayDiffTests.swift
//  ArrayDiffTests
//
//  Created by Adlai Holler on 10/1/15.
//  Copyright © 2015 Adlai Holler. All rights reserved.
//

import XCTest
@testable import ArrayDiff

class ArrayDiffTests: XCTestCase {
	
    func testACommonCase() {
      let old = "a b c d e".components(separatedBy:" ")
      let new = "m a b f".components(separatedBy:" ")
		
		let allFirstIndexes = IndexSet(integersIn: 0..<old.count)
		
		var expectedRemoves = IndexSet()
    expectedRemoves.insert(integersIn: 2..<5)

		var expectedInserts = IndexSet()
		expectedInserts.insert(0)
		expectedInserts.insert(3)
		

    let expectedCommonObjects = "a b".components(separatedBy:" ")

		let diff = old.diff(new)
		
		XCTAssertEqual(expectedInserts, diff.insertedIndexes)
		XCTAssertEqual(expectedRemoves, diff.removedIndexes)
		XCTAssertEqual(expectedCommonObjects, old[diff.commonIndexes])
		
		var removedPlusCommon = diff.removedIndexes
    diff.commonIndexes.forEach { removedPlusCommon.insert($0) }
		XCTAssertEqual(removedPlusCommon, allFirstIndexes)
		
		var reconstructed = old
		reconstructed.removeAtIndexes(diff.removedIndexes)
		reconstructed.insertElements(new[diff.insertedIndexes], atIndexes: diff.insertedIndexes)
		XCTAssertEqual(reconstructed, new)
    }
	
	func testNewIndexForOldIndex() {
    let old = "a b c d e".components(separatedBy:" ")
    let new = "m a b f".components(separatedBy:" ")
		let diff = old.diff(new)
		let newIndexes: [Int?] = (0..<old.count).map { diff.newIndexForOldIndex($0) }
		let expectedNewIndexes: [Int?] = [1, 2, nil, nil, nil]
		XCTAssert(newIndexes.elementsEqual(expectedNewIndexes, by: { $0 == $1 }), "Expected newIndexes to be \(expectedNewIndexes), got \(newIndexes)")
	}
	
	func testNewIndexForOldIndexWithInsertTail() {
		let old = "a b c d".components(separatedBy:" ")
		let new = "a b c e f g j h d".components(separatedBy:" ")
		let diff = old.diff(new)
		let newIndexes: [Int?] = (0..<old.count).map { diff.newIndexForOldIndex($0) }
		let expectedNewIndexes: [Int?] = [0, 1, 2, 8]
		XCTAssert(newIndexes.elementsEqual(expectedNewIndexes, by: { $0 == $1 }), "Expected newIndexes to be \(expectedNewIndexes), got \(newIndexes)")
	}
	
	func testOldIndexForNewIndex() {
		let old = "a b c d e".components(separatedBy:" ")
		let new = "m a b f".components(separatedBy:" ")
		let diff = old.diff(new)
		let oldIndexes: [Int?] = (0..<new.count).map { diff.oldIndexForNewIndex($0) }
		let expectedOldIndexes: [Int?] = [nil, 0, 1, nil]
		XCTAssert(oldIndexes.elementsEqual(expectedOldIndexes, by: { $0 == $1 }), "Expected oldIndexes to be \(expectedOldIndexes), got \(oldIndexes)")
	}
	
	func testCustomEqualityOperator() {
		let old = "a b c d e".components(separatedBy:" ")
		let oldWrapped = old.map { TestType(value: $0) }
		let new = "m a b f".components(separatedBy:" ")
		let newWrapped = new.map { TestType(value: $0) }
		let diff = oldWrapped.diff(newWrapped, elementsAreEqual: TestType.customEqual)
		var reconstructed = oldWrapped
		reconstructed.removeAtIndexes(diff.removedIndexes)
		reconstructed.insertElements(newWrapped[diff.insertedIndexes], atIndexes: diff.insertedIndexes)
		let reconstructedUnwrapped = reconstructed.map { $0.value }
		XCTAssertEqual(reconstructedUnwrapped, new)
	}
	
	func testSectionsSubscriptAtIndexPath() {
		let sections = [
			BasicSection(name: "Alpha", items: [1, 2, 3]),
			BasicSection(name: "Beta", items: [4, 5])
		]
		let indexPath0 = NSIndexPath(indexes: [0, 3], length: 2) as IndexPath
		XCTAssertNil(sections[indexPath0])
		let indexPath1 = NSIndexPath(indexes: [2, 0], length: 2) as IndexPath
		XCTAssertNil(sections[indexPath1])
		let indexPath2 = NSIndexPath(indexes: [0, 2], length: 2) as IndexPath
		XCTAssertEqual(sections[indexPath2], 3)
		let indexPath3 = NSIndexPath(indexes: [1, 0], length: 2) as IndexPath
		XCTAssertEqual(sections[indexPath3], 4)
	}
}

struct TestType {
	var value: String
	
	static func customEqual(t0: TestType, t1: TestType) -> Bool {
		return t0.value == t1.value
	}
}
