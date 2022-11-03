//
//  Collections.swift
//  
//
//  Created by Maksym Kulyk on 04.05.2022.
//

//MARK: - Collection
public extension Sequence
{
    /// - Warning: Will be removed when problems with [SE-0220](https://github.com/apple/swift-evolution/blob/main/proposals/0220-count-where.md) are resolved.
    @inlinable
    func count(where condition: (Self.Element) throws -> Bool) rethrows -> Int
    {
        return try self.lazy.filter(condition).count
    }
}

//MARK: - Collection
public extension Collection
{
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    @inlinable
    subscript (safe index: Self.Index) -> Self.Element?
    {
        return indices.contains(index) ? self[index] : nil
    }
}

//MARK: - Dictionary
public extension Dictionary where Value: Equatable
{
    @inlinable
    func minus(dict: [Key:Value]) -> [Key:Value]
    {
        let entriesInSelfAndNotInDict = filter { dict[$0.0] != self[$0.0] }
        return entriesInSelfAndNotInDict.reduce(into: [:]) { (res, entry) in
            let (key, val) = entry
            res[key] = val
        }
    }
}

//MARK: - Array
public extension Array
{
    @inlinable
    func chunked(into size: Int) -> [[Element]]
    {
        return stride(from: 0, to: count, by: size).map
        {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    @inlinable
    subscript(safe range: CountableRange<Index>) -> ArraySlice<Element>
    {
        let start = Swift.max(range.lowerBound, startIndex)
        let end = Swift.min(range.upperBound, endIndex)
        if end <= start  { return [] }
        return self[start..<end]
    }
    
    @inlinable
    subscript(safe range: CountableClosedRange<Index>) -> ArraySlice<Element>
    {
        let start = Swift.max(range.lowerBound, startIndex)
        let end = Swift.min(range.upperBound, endIndex - 1)
        if end < start { return [] }
        return self[start...end]
    }
}

//MARK: - StackProtocol
public protocol StackProtocol
{
    associatedtype Element
    func peek() -> Element?
    mutating func push(_ element: Element)
    mutating func pop() -> Element?
}

public extension StackProtocol
{
    @inlinable
    var isEmpty: Bool { peek() == nil }
}

public struct Stack<Element>: StackProtocol where Element: Equatable
{
    @usableFromInline internal var storage = [Element]()
    @inlinable public func peek() -> Element? { storage.last }
    @inlinable public mutating func push(_ element: Element) { storage.append(element)  }
    @discardableResult
    @inlinable public mutating func pop() -> Element? { storage.popLast() }
}

extension Stack: Equatable
{
    @inlinable
    public static func == (lhs: Stack<Element>, rhs: Stack<Element>) -> Bool { lhs.storage == rhs.storage }
}

extension Stack: CustomStringConvertible
{
    @inlinable
    public var description: String { "\(storage)" }
}

extension Stack: ExpressibleByArrayLiteral
{
    @inlinable
    public init(arrayLiteral elements: Self.Element...) { storage = elements }
}

// MARK: LinkedList
public class Node<T>
{
    public var value: T
    public var next: Node<T>?
    public weak var previous: Node<T>?
    
    @inlinable
    init(value: T)
    {
        self.value = value
    }
}

public class LinkedList<T>
{
    @usableFromInline internal var head: Node<T>?
    @usableFromInline internal var tail: Node<T>?
    
    @inlinable
    public init() {}
    
    @inlinable
    public var isEmpty: Bool
    {
        return head == nil
    }
    
    @inlinable
    public var first: Node<T>?
    {
        return head
    }
    
    @inlinable
    public var last: Node<T>?
    {
        return tail
    }
    
    @inlinable
    public func append(_ value: T)
    {
        let newNode = Node(value: value)
        if let tailNode = tail
        {
            newNode.previous = tailNode
            tailNode.next = newNode
        }
        else
        {
            head = newNode
        }
        tail = newNode
    }
    
    @inlinable
    public func nodeAt(_ index: Int) -> Node<T>?
    {
        if index >= 0
        {
            var node = head
            var i = index
            while node != nil
            {
                if i == 0 { return node }
                i -= 1
                node = node!.next
            }
        }
        return nil
    }
    
    @inlinable
    public func removeAll()
    {
        head = nil
        tail = nil
    }
    
    @inlinable
    @discardableResult
    public func remove(_ node: Node<T>) -> T
    {
        let prev = node.previous
        let next = node.next
        
        if let prev = prev
        {
            prev.next = next
        }
        else
        {
            head = next
        }
        next?.previous = prev
        
        if next == nil
        {
            tail = prev
        }
        
        node.previous = nil
        node.next = nil
        
        return node.value
    }
}

extension LinkedList: CustomStringConvertible
{
    @inlinable
    public var description: String
    {
        var text = "["
        var node = head
        while node != nil
        {
            text += "\(node!.value)"
            node = node!.next
            if node != nil { text += ", " }
        }
        return text + "]"
    }
}

// MARK: - Queue
/// ``LinkedList`` based Queue.
public struct Queue<T>
{
    @usableFromInline internal var list = LinkedList<T>()
    
    @inlinable
    public init() {}
    
    @inlinable
    public var isEmpty: Bool
    {
        return list.isEmpty
    }
    
    @inlinable
    public mutating func enqueue(_ element: T)
    {
        list.append(element)
    }
    
    @inlinable
    public mutating func dequeue() -> T?
    {
        guard !list.isEmpty, let element = list.first else { return nil }
        
        list.remove(element)
        
        return element.value
    }
    
    @inlinable
    public func peek() -> T?
    {
        return list.first?.value
    }
}

extension Queue: CustomStringConvertible
{
    @inlinable
    public var description: String
    {
        return list.description
    }
}

// MARK: - FastQueue
/// Array based `FIFO` queue with `O(1) ammortized` complexity for enqueuing and dequeuing operations.
public struct FastQueue<T>
{
    @usableFromInline internal var array = [T?]()
    @usableFromInline internal var head = 0
    
    @inlinable
    public init() {}
    
    @inlinable
    public var isEmpty: Bool
    {
        return count == 0
    }
    
    @inlinable
    public var count: Int
    {
        return array.count - head
    }
    
    @inlinable
    public mutating func enqueue(_ element: T)
    {
        array.append(element)
    }
    
    @inlinable
    public mutating func dequeue() -> T?
    {
        guard let element = array[safe: head] else { return nil }
        
        array[head] = nil
        head += 1
        
        let percentage = Double(head)/Double(array.count)
        if array.count > 50 && percentage > 0.25
        {
            array.removeFirst(head)
            head = 0
        }
        
        return element
    }
    
    @inlinable
    public func peek() -> T?
    {
        if isEmpty
        {
            return nil
        }
        else
        {
            return array[head]
        }
    }
}

extension FastQueue: CustomStringConvertible
{
    @inlinable
    public var description: String
    {
        return array[head..<array.count].description
    }
}

// MARK: - Heap
public struct Heap<T>
{
    /// The array that stores the heap's nodes.
    @usableFromInline internal var nodes = [T]()
    
    /// Determines how to compare two nodes in the heap.
    /// Use '>' for a max-heap or '<' for a min-heap,
    /// or provide a comparing method if the heap is made
    /// of custom elements, for example tuples.
    @usableFromInline internal var orderCriteria: (T, T) -> Bool
    
    /// Creates an empty heap.
    /// The sort function determines whether this is a min-heap or max-heap.
    /// For comparable data types, > makes a max-heap, < makes a min-heap.
    @inlinable
    public init(sort: @escaping (T, T) -> Bool)
    {
        self.orderCriteria = sort
    }
    
    /// Creates a heap from an array. The order of the array does not matter;
    /// the elements are inserted into the heap in the order determined by the
    /// sort function. For comparable data types, '>' makes a max-heap,
    /// '<' makes a min-heap.
    @inlinable
    public init(array: [T], sort: @escaping (T, T) -> Bool)
    {
        self.orderCriteria = sort
        configureHeap(from: array)
    }
    
    /// Configures the max-heap or min-heap from an array, in a bottom-up manner.
    /// Performance: This runs pretty much in O(n).
    @usableFromInline
    internal mutating func configureHeap(from array: [T])
    {
        nodes = array
        for i in stride(from: (nodes.count/2-1), through: 0, by: -1)
        {
            shiftDown(i)
        }
    }
    
    @inlinable
    public var isEmpty: Bool
    {
        return nodes.isEmpty
    }
    
    @inlinable
    public var count: Int
    {
        return nodes.count
    }
    
    /// Returns the index of the parent of the element at index i.
    /// The element at index 0 is the root of the tree and has no parent.
    @inline(__always)
    @usableFromInline
    internal func parentIndex(ofIndex i: Int) -> Int {
        return (i - 1) / 2
    }
    
    /// Returns the index of the left child of the element at index i.
    /// Note that this index can be greater than the heap size, in which case
    /// there is no left child.
    @inline(__always)
    @usableFromInline
    internal func leftChildIndex(ofIndex i: Int) -> Int {
        return 2*i + 1
    }
    
    /// Returns the index of the right child of the element at index i.
    /// Note that this index can be greater than the heap size, in which case
    /// there is no right child.
    @inline(__always)
    @usableFromInline
    internal func rightChildIndex(ofIndex i: Int) -> Int {
        return 2*i + 2
    }
    
    /// Returns the maximum value in the heap (for a max-heap) or the minimum
    /// value (for a min-heap).
    @inlinable
    public func peek() -> T?
    {
        return nodes.first
    }
    
    /// Adds a new value to the heap. This reorders the heap so that the max-heap
    /// or min-heap property still holds. Performance: O(log n).
    @inlinable
    public mutating func insert(_ value: T)
    {
        nodes.append(value)
        shiftUp(nodes.count - 1)
    }
    
    /// Adds a sequence of values to the heap. This reorders the heap so that
    /// the max-heap or min-heap property still holds. Performance: O(log n).
    @inlinable
    public mutating func insert<S: Sequence>(_ sequence: S) where S.Iterator.Element == T
    {
        for value in sequence {
            insert(value)
        }
    }
    
    /// Allows you to change an element. This reorders the heap so that
    /// the max-heap or min-heap property still holds.
    @inlinable
    public mutating func replace(index i: Int, value: T)
    {
        guard i < nodes.count else { return }
        
        remove(at: i)
        insert(value)
    }
    
    /// Removes the root node from the heap. For a max-heap, this is the maximum
    /// value; for a min-heap it is the minimum value. Performance: O(log n).
    @inlinable
    @discardableResult
    public mutating func remove() -> T?
    {
        guard !nodes.isEmpty else { return nil }
        
        if nodes.count == 1 {
            return nodes.removeLast()
        } else {
            // Use the last node to replace the first one, then fix the heap by
            // shifting this new first node into its proper position.
            let value = nodes[0]
            nodes[0] = nodes.removeLast()
            shiftDown(0)
            return value
        }
    }
    
    /// Removes an arbitrary node from the heap. Performance: O(log n).
    /// Note that you need to know the node's index.
    @inlinable
    @discardableResult
    public mutating func remove(at index: Int) -> T?
    {
        guard index < nodes.count else { return nil }
        
        let size = nodes.count - 1
        if index != size {
            nodes.swapAt(index, size)
            shiftDown(from: index, until: size)
            shiftUp(index)
        }
        return nodes.removeLast()
    }
    
    /// Takes a child node and looks at its parents; if a parent is not larger
    /// (max-heap) or not smaller (min-heap) than the child, we exchange them.
    @usableFromInline
    internal mutating func shiftUp(_ index: Int)
    {
        var childIndex = index
        let child = nodes[childIndex]
        var parentIndex = self.parentIndex(ofIndex: childIndex)
        
        while childIndex > 0 && orderCriteria(child, nodes[parentIndex]) {
            nodes[childIndex] = nodes[parentIndex]
            childIndex = parentIndex
            parentIndex = self.parentIndex(ofIndex: childIndex)
        }
        
        nodes[childIndex] = child
    }
    
    /// Looks at a parent node and makes sure it is still larger (max-heap) or
    /// smaller (min-heap) than its childeren.
    @usableFromInline
    internal mutating func shiftDown(from index: Int, until endIndex: Int)
    {
        let leftChildIndex = self.leftChildIndex(ofIndex: index)
        let rightChildIndex = leftChildIndex + 1
        
        // Figure out which comes first if we order them by the sort function:
        // the parent, the left child, or the right child. If the parent comes
        // first, we're done. If not, that element is out-of-place and we make
        // it "float down" the tree until the heap property is restored.
        var first = index
        if leftChildIndex < endIndex && orderCriteria(nodes[leftChildIndex], nodes[first]) {
            first = leftChildIndex
        }
        if rightChildIndex < endIndex && orderCriteria(nodes[rightChildIndex], nodes[first]) {
            first = rightChildIndex
        }
        if first == index { return }
        
        nodes.swapAt(index, first)
        shiftDown(from: first, until: endIndex)
    }
    
    @usableFromInline
    internal mutating func shiftDown(_ index: Int)
    {
        shiftDown(from: index, until: nodes.count)
    }
    
}

// MARK: Heap Searching
extension Heap where T: Equatable
{
    /// Get the index of a node in the heap. Performance: O(n).
    @inlinable
    public func index(of node: T) -> Int?
    {
        return nodes.firstIndex(where: { $0 == node })
    }
    
    /// Removes the first occurrence of a node from the heap. Performance: O(n).
    @inlinable
    @discardableResult
    public mutating func remove(node: T) -> T?
    {
        if let index = index(of: node) {
            return remove(at: index)
        }
        return nil
    }
}

// MARK: - PriorityQueue
/// Heap based priority queue with `O(lg n)` complexity for all operations.
public struct PriorityQueue<T>
{
    @usableFromInline internal var heap: Heap<T>
    
    /// To create a max-priority queue, supply a > sort function. For a min-priority
    /// queue, use <.
    @inlinable
    public init(sort: @escaping (T, T) -> Bool)
    {
        heap = Heap(sort: sort)
    }
    
    @inlinable
    public var isEmpty: Bool
    {
        return heap.isEmpty
    }
    
    @inlinable
    public var count: Int
    {
        return heap.count
    }
    
    @inlinable
    public func peek() -> T?
    {
        return heap.peek()
    }
    
    @inlinable
    public mutating func enqueue(_ element: T)
    {
        heap.insert(element)
    }
    
    @inlinable
    public mutating func dequeue() -> T?
    {
        return heap.remove()
    }
    
    /// Allows you to change the priority of an element. In a max-priority queue,
    /// the new priority should be larger than the old one; in a min-priority queue
    /// it should be smaller.
    @inlinable
    public mutating func changePriority(index i: Int, value: T)
    {
        return heap.replace(index: i, value: value)
    }
}

// MARK: HashedHeap
/// Heap with an index hash map (dictionary) to speed up lookups by value.
///
/// A heap keeps elements ordered in a binary tree without the use of pointers. A hashed heap does that as well as
/// having amortized constant lookups by value. This is used in the A* and other heuristic search algorithms to achieve
/// optimal performance.
public struct HashedHeap<T: Hashable>
{
    // TODO: use `public internal(set)` instead of internal var + public var getter when [SR-7590](https://github.com/apple/swift/issues/50132) gets fixed
    
    /// The array that stores the heap's nodes.
    @usableFromInline internal var _elements = [T]()
    
    /// The array that stores the heap's nodes.
    public var elements: [T] { _elements }
    
    /// Hash mapping from elements to indices in the `elements` array.
    @usableFromInline internal var _indices = [T: Int]()
    
    /// Hash mapping from elements to indices in the `elements` array.
    public var indices: [T: Int] { _indices }
    
    /// Determines whether this is a max-heap (>) or min-heap (<).
    @usableFromInline internal var isOrderedBefore: (T, T) -> Bool
    
    /// Creates an empty hashed heap.
    ///
    /// The sort function determines whether this is a min-heap or max-heap. For integers, > makes a max-heap, < makes
    /// a min-heap.
    @inlinable
    public init(sort: @escaping (T, T) -> Bool)
    {
        isOrderedBefore = sort
    }
    
    /// Creates a hashed heap from an array.
    ///
    /// The order of the array does not matter; the elements are inserted into the heap in the order determined by the
    /// sort function.
    ///
    /// - Complexity: O(n)
    @inlinable
    public init(array: [T], sort: @escaping (T, T) -> Bool)
    {
        isOrderedBefore = sort
        build(from: array)
    }
    
    /// Converts an array to a max-heap or min-heap in a bottom-up manner.
    ///
    /// - Complexity: O(n)
    @usableFromInline
    internal mutating func build(from array: [T]) {
        _elements = array
        for index in _elements.indices {
            _indices[_elements[index]] = index
        }
        
        for i in stride(from: (_elements.count/2 - 1), through: 0, by: -1) {
            shiftDown(i, heapSize: _elements.count)
        }
    }
    
    /// Whether the heap is empty.
    @inlinable
    public var isEmpty: Bool
    {
        return _elements.isEmpty
    }
    
    /// The number of elements in the heap.
    @inlinable
    public var count: Int
    {
        return _elements.count
    }
    
    /// Accesses an element by its index.
    @inlinable
    public subscript(index: Int) -> T
    {
        return _elements[index]
    }
    
    /// Returns the index of the given element.
    ///
    /// This is the operation that a hashed heap optimizes in compassion with a normal heap. In a normal heap this
    /// would take O(n), but for the hashed heap this takes amortized constatn time.
    ///
    /// - Complexity: Amortized constant
    @inlinable
    public func index(of element: T) -> Int?
    {
        return _indices[element]
    }
    
    /// Returns the maximum value in the heap (for a max-heap) or the minimum value (for a min-heap).
    ///
    /// - Complexity: O(1)
    @inlinable
    public func peek() -> T?
    {
        return _elements.first
    }
    
    /// Adds a new value to the heap.
    ///
    /// This reorders the heap so that the max-heap or min-heap property still holds.
    ///
    /// - Complexity: O(log n)
    @inlinable
    public mutating func insert(_ value: T)
    {
        _elements.append(value)
        _indices[value] = _elements.count - 1
        shiftUp(_elements.count - 1)
    }
    
    /// Adds new values to the heap.
    @inlinable
    public mutating func insert<S: Sequence>(_ sequence: S) where S.Iterator.Element == T
    {
        for value in sequence {
            insert(value)
        }
    }
    
    /// Replaces an element in the hash.
    ///
    /// In a max-heap, the new element should be larger than the old one; in a min-heap it should be smaller.
    @inlinable
    public mutating func replace(_ value: T, at index: Int)
    {
        guard index < _elements.count else { return }
        
        assert(isOrderedBefore(value, _elements[index]))
        set(value, at: index)
        shiftUp(index)
    }
    
    /// Removes the root node from the heap.
    ///
    /// For a max-heap, this is the maximum value; for a min-heap it is the minimum value.
    ///
    /// - Complexity: O(log n)
    @inlinable
    @discardableResult
    public mutating func remove() -> T?
    {
        if _elements.isEmpty {
            return nil
        } else if _elements.count == 1 {
            return removeLast()
        } else {
            // Use the last node to replace the first one, then fix the heap by
            // shifting this new first node into its proper position.
            let value = _elements[0]
            set(removeLast(), at: 0)
            shiftDown()
            return value
        }
    }
    
    /// Removes an arbitrary node from the heap.
    ///
    /// You need to know the node's index, which may actually take O(n) steps to find.
    ///
    /// - Complexity: O(log n).
    @inlinable
    public mutating func remove(at index: Int) -> T?
    {
        guard index < _elements.count else { return nil }
        
        let size = _elements.count - 1
        if index != size {
            swapAt(index, size)
            shiftDown(index, heapSize: size)
            shiftUp(index)
        }
        return removeLast()
    }
    
    /// Removes all elements from the heap.
    @inlinable
    public mutating func removeAll()
    {
        _elements.removeAll()
        _indices.removeAll()
    }
    
    /// Removes the last element from the heap.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func removeLast() -> T {
        guard let value = _elements.last else {
            preconditionFailure("Trying to remove element from empty heap")
        }
        _indices[value] = nil
        return _elements.removeLast()
    }
    
    /// Takes a child node and looks at its parents; if a parent is not larger (max-heap) or not smaller (min-heap)
    /// than the child, we exchange them.
    @usableFromInline
    internal mutating func shiftUp(_ index: Int) {
        var childIndex = index
        let child = _elements[childIndex]
        var parentIndex = self.parentIndex(of: childIndex)
        
        while childIndex > 0 && isOrderedBefore(child, _elements[parentIndex]) {
            set(_elements[parentIndex], at: childIndex)
            childIndex = parentIndex
            parentIndex = self.parentIndex(of: childIndex)
        }
        
        set(child, at: childIndex)
    }
    
    @usableFromInline
    internal mutating func shiftDown()
    {
        shiftDown(0, heapSize: _elements.count)
    }
    
    /// Looks at a parent node and makes sure it is still larger (max-heap) or smaller (min-heap) than its childeren.
    @usableFromInline
    internal mutating func shiftDown(_ index: Int, heapSize: Int) {
        var parentIndex = index
        
        while true {
            let leftChildIndex = self.leftChildIndex(of: parentIndex)
            let rightChildIndex = leftChildIndex + 1
            
            // Figure out which comes first if we order them by the sort function:
            // the parent, the left child, or the right child. If the parent comes
            // first, we're done. If not, that element is out-of-place and we make
            // it "float down" the tree until the heap property is restored.
            var first = parentIndex
            if leftChildIndex < heapSize && isOrderedBefore(_elements[leftChildIndex], _elements[first]) {
                first = leftChildIndex
            }
            if rightChildIndex < heapSize && isOrderedBefore(_elements[rightChildIndex], _elements[first]) {
                first = rightChildIndex
            }
            if first == parentIndex { return }
            
            swapAt(parentIndex, first)
            parentIndex = first
        }
    }
    
    /// Replaces an element in the heap and updates the indices hash.
    @usableFromInline
    internal mutating func set(_ newValue: T, at index: Int) {
        _indices[_elements[index]] = nil
        _elements[index] = newValue
        _indices[newValue] = index
    }
    
    /// Swap two elements in the heap and update the indices hash.
    @usableFromInline
    internal mutating func swapAt(_ i: Int, _ j: Int) {
        _elements.swapAt(i, j)
        _indices[_elements[i]] = i
        _indices[_elements[j]] = j
    }
    
    /// Returns the index of the parent of the element at index i.
    ///
    /// - Note: The element at index 0 is the root of the tree and has no parent.
    @inline(__always)
    internal func parentIndex(of index: Int) -> Int {
        return (index - 1) / 2
    }
    
    /// Returns the index of the left child of the element at index i.
    ///
    /// - Note: this index can be greater than the heap size, in which case there is no left child.
    @inline(__always)
    internal func leftChildIndex(of index: Int) -> Int {
        return 2*index + 1
    }
    
    /// Returns the index of the right child of the element at index i.
    ///
    /// - Note: this index can be greater than the heap size, in which case there is no right child.
    @inline(__always)
    internal func rightChildIndex(of index: Int) -> Int {
        return 2*index + 2
    }
}
