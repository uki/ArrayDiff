
/**
Types that conform to this protocol represent a section of a table.

- See: `NamedSection` for an example implementation
*/
public protocol SectionType: Equatable {
	associatedtype Item: Equatable
	var items: [Item] { get }
}

public extension Array where Element: SectionType {
	/**
	For an array of SectionTypes, returns a compact list of the counts. This is useful for debugging changes.
	
	- Returns: A string like "<sectionCount: 4 itemCounts: [0: 16], [1: 25], [2: 17], [3: 4]>"
	*/
	public var nestedDescription: String {
		let countsStr = enumerated().map { "[\($0): \($1.items.count)]" }.joined(separator: ", ")
		return "<sectionCount: \(count) itemCounts: \(countsStr)>"
	}
	
	/**
	Attempt to retrieve the item at the given index path. Returns nil if the index is out of bounds.
	*/
	public subscript (indexPath: IndexPath) -> Element.Item? {
		guard let sectionIndex = indexPath.first, indices.contains(sectionIndex) else { return nil }
		
		let section = self[sectionIndex]
		let itemIndex = indexPath[1]
		guard section.items.indices.contains(itemIndex) else { return nil }
		
		return section.items[itemIndex]
	}
}

/**
An example implementation of SectionType that uses a name to compare sections
*/
public struct BasicSection<Item: Equatable>: SectionType {
	public var name: String
	public var items: [Item]
	
	public init(name: String, items: [Item]) {
		self.name = name
		self.items = items
	}
}

public func ==<Item>(section0: BasicSection<Item>, section1: BasicSection<Item>) -> Bool {
	return section0.name == section1.name
}

public struct NestedDiff {
	public let sectionsDiff: ArrayDiff
	public let itemDiffs: [ArrayDiff?]
	
	/**
	Determine the new index path, if any, for the given old index path.
	- Returns: The index path after the update, or nil if the item was removed
	*/
	public func newIndexPathForOldIndexPath(_ indexPath: IndexPath) -> IndexPath? {
		if let oldSection = indexPath.first,
       let newSection = sectionsDiff.newIndexForOldIndex(oldSection),
       let newItem = itemDiffs[oldSection]?.newIndexForOldIndex(indexPath[1]) {
			return (NSIndexPath(indexes: [newSection, newItem], length: 2) as IndexPath)
		} else {
			return nil
		}
	}

	/**
	Determine the new index path, if any, for the given old index path.
	- Returns: The index path before the update, or nil if the item was inserted
	*/
	public func oldIndexPathForNewIndexPath(_ newIndexPath: IndexPath) -> IndexPath? {
		if let oldSection = sectionsDiff.oldIndexForNewIndex(newIndexPath[0]),
    	 let oldItem = itemDiffs[oldSection]?.oldIndexForNewIndex(newIndexPath[1]) {
			return (NSIndexPath(indexes: [oldSection, oldItem], length: 2) as IndexPath)
		} else {
			return nil
		}
	}
    
    /**
     Returns true iff there are no changes to the sections or items in this diff
    */
    public var isEmpty: Bool {
        return sectionsDiff.isEmpty && !itemDiffs.contains { diffOrNil in
            if let diff = diffOrNil {
                return !diff.isEmpty
            } else {
                return false
            }
        }
    }
}

public extension Array where Element: SectionType {
	/**
		Compute the diffs at the section level plus the item diffs for all sections that survived the change.
		Sections are considered equal if their metadatas are equal.
	
	
		- Parameter newData: The new array of Sections
	
		- Returns: The section-level diff plus item diffs for each section that was not removed/inserted.
	itemDiffs is indexed based on the _old_ section indexes.
	
	*/
	public func diffNested(_ newData: Array<Element>) -> NestedDiff {
		let sectionDiff = diff(newData)
		
		// diffs will exist for all sections that weren't deleted or inserted
		let itemDiffs: [ArrayDiff?] = self.enumerated().map { oldSectionIndex, oldSectionInfo in
			if let newSection = sectionDiff.newIndexForOldIndex(oldSectionIndex) {
				assert(newData[newSection] == oldSectionInfo, "Diffing for the wrong section!")
				return oldSectionInfo.items.diff(newData[newSection].items)
			} else {
				return nil
			}
		}
		
		return NestedDiff(sectionsDiff: sectionDiff, itemDiffs: itemDiffs)
	}
}
