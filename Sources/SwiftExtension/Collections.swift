//
//  Collections.swift
//  
//
//  Created by zeewanderer on 04.05.2022.
//

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
    @usableFromInline internal var p_head: Node<T>?
    @usableFromInline internal var p_tail: Node<T>?
    
    @inlinable
    public init() {}
    
    @inlinable
    public var isEmpty: Bool
    {
        return p_head == nil
    }
    
    @inlinable
    public var first: Node<T>?
    {
        return p_head
    }
    
    @inlinable
    public var last: Node<T>?
    {
        return p_tail
    }
    
    @inlinable
    public func append(_ value: T)
    {
        let newNode = Node(value: value)
        if let tailNode = p_tail
        {
            newNode.previous = tailNode
            tailNode.next = newNode
        }
        else
        {
            p_head = newNode
        }
        p_tail = newNode
    }
    
    @inlinable
    public func nodeAt(_ index: Int) -> Node<T>?
    {
        if index >= 0
        {
            var node = p_head
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
        p_head = nil
        p_tail = nil
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
            p_head = next
        }
        next?.previous = prev
        
        if next == nil
        {
            p_tail = prev
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
        var node = p_head
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
/// ``LinkedList`` based queue with copy-on-write value semantics.
public struct Queue<T>
{
    @usableFromInline internal var p_list = LinkedList<T>()
    
    @inlinable
    public init() {}
    
    @inlinable
    public var isEmpty: Bool
    {
        return p_list.isEmpty
    }
    
    @inlinable
    public mutating func enqueue(_ element: T)
    {
        p_ensureUniqueStorage()
        p_list.append(element)
    }
    
    @inlinable
    public mutating func dequeue() -> T?
    {
        guard !p_list.isEmpty else { return nil }

        p_ensureUniqueStorage()
        guard let element = p_list.first else { return nil }
        p_list.remove(element)
        
        return element.value
    }
    
    @inlinable
    public func peek() -> T?
    {
        return p_list.first?.value
    }

    @usableFromInline
    internal mutating func p_ensureUniqueStorage()
    {
        guard !isKnownUniquelyReferenced(&p_list) else { return }

        let copy = LinkedList<T>()
        var node = p_list.first
        while let current = node {
            copy.append(current.value)
            node = current.next
        }
        p_list = copy
    }
}

extension Queue: CustomStringConvertible
{
    @inlinable
    public var description: String
    {
        return p_list.description
    }
}

// MARK: - FastQueue
/// Array based `FIFO` queue with `O(1) ammortized` complexity for enqueuing and dequeuing operations.
public struct FastQueue<T>
{
    @usableFromInline internal var p_array = [T?]()
    @usableFromInline internal var p_head = 0
    
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
        return p_array.count - p_head
    }
    
    @inlinable
    public mutating func enqueue(_ element: T)
    {
        p_array.append(element)
    }
    
    @inlinable
    public mutating func dequeue() -> T?
    {
        guard let element = p_array[safe: p_head] else { return nil }
        
        p_array[p_head] = nil
        p_head += 1
        
        let percentage = Double(p_head)/Double(p_array.count)
        if p_array.count > 50 && percentage > 0.25
        {
            p_array.removeFirst(p_head)
            p_head = 0
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
            return p_array[p_head]
        }
    }
}

extension FastQueue: CustomStringConvertible
{
    @inlinable
    public var description: String
    {
        return p_array[p_head..<p_array.count].description
    }
}

// MARK: - Heap
public struct Heap<T>
{
    /// The array that stores the heap's nodes.
    @usableFromInline internal var p_nodes = [T]()
    
    /// Determines how to compare two nodes in the heap.
    /// Use '>' for a max-heap or '<' for a min-heap,
    /// or provide a comparing method if the heap is made
    /// of custom elements, for example tuples.
    @usableFromInline internal var p_orderCriteria: (T, T) -> Bool
    
    /// Creates an empty heap.
    /// The sort function determines whether this is a min-heap or max-heap.
    /// For comparable data types, > makes a max-heap, < makes a min-heap.
    @inlinable
    public init(sort: @escaping (T, T) -> Bool)
    {
        self.p_orderCriteria = sort
    }
    
    /// Creates a heap from an array. The order of the array does not matter;
    /// the elements are inserted into the heap in the order determined by the
    /// sort function. For comparable data types, '>' makes a max-heap,
    /// '<' makes a min-heap.
    @inlinable
    public init(array: [T], sort: @escaping (T, T) -> Bool)
    {
        self.p_orderCriteria = sort
        p_configureHeap(from: array)
    }
    
    /// Configures the max-heap or min-heap from an array, in a bottom-up manner.
    /// Performance: This runs pretty much in O(n).
    @usableFromInline
    internal mutating func p_configureHeap(from array: [T])
    {
        p_nodes = array
        for i in stride(from: (p_nodes.count/2-1), through: 0, by: -1)
        {
            p_shiftDown(i)
        }
    }
    
    @inlinable
    public var isEmpty: Bool
    {
        return p_nodes.isEmpty
    }
    
    @inlinable
    public var count: Int
    {
        return p_nodes.count
    }
    
    /// Returns the index of the parent of the element at index i.
    /// The element at index 0 is the root of the tree and has no parent.
    @inline(__always)
    @usableFromInline
    internal func p_parentIndex(ofIndex i: Int) -> Int {
        return (i - 1) / 2
    }
    
    /// Returns the index of the left child of the element at index i.
    /// Note that this index can be greater than the heap size, in which case
    /// there is no left child.
    @inline(__always)
    @usableFromInline
    internal func p_leftChildIndex(ofIndex i: Int) -> Int {
        return 2*i + 1
    }
    
    /// Returns the index of the right child of the element at index i.
    /// Note that this index can be greater than the heap size, in which case
    /// there is no right child.
    @inline(__always)
    @usableFromInline
    internal func p_rightChildIndex(ofIndex i: Int) -> Int {
        return 2*i + 2
    }
    
    /// Returns the maximum value in the heap (for a max-heap) or the minimum
    /// value (for a min-heap).
    @inlinable
    public func peek() -> T?
    {
        return p_nodes.first
    }
    
    /// Adds a new value to the heap. This reorders the heap so that the max-heap
    /// or min-heap property still holds. Performance: O(log n).
    @inlinable
    public mutating func insert(_ value: T)
    {
        p_nodes.append(value)
        p_shiftUp(p_nodes.count - 1)
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
        guard i >= 0, i < p_nodes.count else { return }
        
        remove(at: i)
        insert(value)
    }
    
    /// Removes the root node from the heap. For a max-heap, this is the maximum
    /// value; for a min-heap it is the minimum value. Performance: O(log n).
    @inlinable
    @discardableResult
    public mutating func remove() -> T?
    {
        guard !p_nodes.isEmpty else { return nil }
        
        if p_nodes.count == 1 {
            return p_nodes.removeLast()
        } else {
            // Use the last node to replace the first one, then fix the heap by
            // shifting this new first node into its proper position.
            let value = p_nodes[0]
            p_nodes[0] = p_nodes.removeLast()
            p_shiftDown(0)
            return value
        }
    }
    
    /// Removes an arbitrary node from the heap. Performance: O(log n).
    /// Note that you need to know the node's index.
    @inlinable
    @discardableResult
    public mutating func remove(at index: Int) -> T?
    {
        guard index >= 0, index < p_nodes.count else { return nil }
        
        let size = p_nodes.count - 1
        if index != size {
            p_nodes.swapAt(index, size)
            p_shiftDown(from: index, until: size)
            p_shiftUp(index)
        }
        return p_nodes.removeLast()
    }
    
    /// Takes a child node and looks at its parents; if a parent is not larger
    /// (max-heap) or not smaller (min-heap) than the child, we exchange them.
    @usableFromInline
    internal mutating func p_shiftUp(_ index: Int)
    {
        var childIndex = index
        let child = p_nodes[childIndex]
        var parentIndex = self.p_parentIndex(ofIndex: childIndex)
        
        while childIndex > 0 && p_orderCriteria(child, p_nodes[parentIndex]) {
            p_nodes[childIndex] = p_nodes[parentIndex]
            childIndex = parentIndex
            parentIndex = self.p_parentIndex(ofIndex: childIndex)
        }
        
        p_nodes[childIndex] = child
    }
    
    /// Looks at a parent node and makes sure it is still larger (max-heap) or
    /// smaller (min-heap) than its childeren.
    @usableFromInline
    internal mutating func p_shiftDown(from index: Int, until endIndex: Int)
    {
        let leftChildIndex = self.p_leftChildIndex(ofIndex: index)
        let rightChildIndex = leftChildIndex + 1
        
        // Figure out which comes first if we order them by the sort function:
        // the parent, the left child, or the right child. If the parent comes
        // first, we're done. If not, that element is out-of-place and we make
        // it "float down" the tree until the heap property is restored.
        var first = index
        if leftChildIndex < endIndex && p_orderCriteria(p_nodes[leftChildIndex], p_nodes[first]) {
            first = leftChildIndex
        }
        if rightChildIndex < endIndex && p_orderCriteria(p_nodes[rightChildIndex], p_nodes[first]) {
            first = rightChildIndex
        }
        if first == index { return }
        
        p_nodes.swapAt(index, first)
        p_shiftDown(from: first, until: endIndex)
    }
    
    @usableFromInline
    internal mutating func p_shiftDown(_ index: Int)
    {
        p_shiftDown(from: index, until: p_nodes.count)
    }
    
}

// MARK: Heap Searching
extension Heap where T: Equatable
{
    /// Get the index of a node in the heap. Performance: O(n).
    @inlinable
    public func index(of node: T) -> Int?
    {
        return p_nodes.firstIndex(where: { $0 == node })
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
    @usableFromInline internal var p_heap: Heap<T>
    
    /// To create a max-priority queue, supply a > sort function. For a min-priority
    /// queue, use <.
    @inlinable
    public init(sort: @escaping (T, T) -> Bool)
    {
        p_heap = Heap(sort: sort)
    }
    
    @inlinable
    public var isEmpty: Bool
    {
        return p_heap.isEmpty
    }
    
    @inlinable
    public var count: Int
    {
        return p_heap.count
    }
    
    @inlinable
    public func peek() -> T?
    {
        return p_heap.peek()
    }
    
    @inlinable
    public mutating func enqueue(_ element: T)
    {
        p_heap.insert(element)
    }
    
    @inlinable
    public mutating func dequeue() -> T?
    {
        return p_heap.remove()
    }
    
    /// Allows you to change the priority of an element. In a max-priority queue,
    /// the new priority should be larger than the old one; in a min-priority queue
    /// it should be smaller.
    @inlinable
    public mutating func changePriority(index i: Int, value: T)
    {
        return p_heap.replace(index: i, value: value)
    }
}

// MARK: HashedHeap
/// Heap with an index hash map (dictionary) to speed up lookups by value.
///
/// A heap keeps elements ordered in a binary tree without the use of pointers. A hashed heap does that as well as
/// having amortized constant lookups by value. This is used in the A* and other heuristic search algorithms to achieve
/// optimal performance.
///
/// Values are unique. Construction keeps the first occurrence of each value,
/// and inserting or replacing with a value already in the heap is a no-op.
public struct HashedHeap<T: Hashable>
{
    // TODO: use `public internal(set)` instead of internal var + public var getter when [SR-7590](https://github.com/apple/swift/issues/50132) gets fixed
    
    /// The array that stores the heap's nodes.
    @usableFromInline internal var p_elements = [T]()
    
    /// The array that stores the heap's nodes.
    public var elements: [T] { p_elements }
    
    /// Hash mapping from elements to indices in the `elements` array.
    @usableFromInline internal var p_indices = [T: Int]()
    
    /// Hash mapping from elements to indices in the `elements` array.
    public var indices: [T: Int] { p_indices }
    
    /// Determines whether this is a max-heap (>) or min-heap (<).
    @usableFromInline internal var p_isOrderedBefore: (T, T) -> Bool
    
    /// Creates an empty hashed heap.
    ///
    /// The sort function determines whether this is a min-heap or max-heap. For integers, > makes a max-heap, < makes
    /// a min-heap.
    @inlinable
    public init(sort: @escaping (T, T) -> Bool)
    {
        p_isOrderedBefore = sort
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
        p_isOrderedBefore = sort
        p_build(from: array)
    }
    
    /// Converts an array to a max-heap or min-heap in a bottom-up manner.
    ///
    /// - Complexity: O(n)
    @usableFromInline
    internal mutating func p_build(from array: [T]) {
        p_elements.removeAll(keepingCapacity: true)
        p_indices.removeAll(keepingCapacity: true)
        for value in array where p_indices[value] == nil {
            p_indices[value] = p_elements.count
            p_elements.append(value)
        }

        if p_elements.count > 1 {
            for i in stride(from: (p_elements.count/2 - 1), through: 0, by: -1) {
                p_shiftDown(i, heapSize: p_elements.count)
            }
        }
    }
    
    /// Whether the heap is empty.
    @inlinable
    public var isEmpty: Bool
    {
        return p_elements.isEmpty
    }
    
    /// The number of elements in the heap.
    @inlinable
    public var count: Int
    {
        return p_elements.count
    }
    
    /// Accesses an element by its index.
    @inlinable
    public subscript(index: Int) -> T
    {
        return p_elements[index]
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
        return p_indices[element]
    }
    
    /// Returns the maximum value in the heap (for a max-heap) or the minimum value (for a min-heap).
    ///
    /// - Complexity: O(1)
    @inlinable
    public func peek() -> T?
    {
        return p_elements.first
    }
    
    /// Adds a new value to the heap.
    ///
    /// This reorders the heap so that the max-heap or min-heap property still holds.
    ///
    /// - Complexity: O(log n)
    @inlinable
    public mutating func insert(_ value: T)
    {
        guard p_indices[value] == nil else { return }
        p_elements.append(value)
        p_indices[value] = p_elements.count - 1
        p_shiftUp(p_elements.count - 1)
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
        guard index >= 0, index < p_elements.count else { return }
        let oldValue = p_elements[index]
        guard oldValue != value else { return }
        guard p_indices[value] == nil else { return }

        p_set(value, at: index)
        if index > 0, p_isOrderedBefore(value, p_elements[p_parentIndex(of: index)]) {
            p_shiftUp(index)
        } else {
            p_shiftDown(index, heapSize: p_elements.count)
        }
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
        if p_elements.isEmpty {
            return nil
        } else if p_elements.count == 1 {
            return removeLast()
        } else {
            // Use the last node to replace the first one, then fix the heap by
            // shifting this new first node into its proper position.
            let value = p_elements[0]
            p_set(removeLast(), at: 0)
            p_shiftDown()
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
        guard index >= 0, index < p_elements.count else { return nil }

        let size = p_elements.count - 1
        if index != size {
            p_swapAt(index, size)
        }
        let removed = removeLast()
        if index < p_elements.count {
            if index > 0, p_isOrderedBefore(p_elements[index], p_elements[p_parentIndex(of: index)]) {
                p_shiftUp(index)
            } else {
                p_shiftDown(index, heapSize: p_elements.count)
            }
        }
        return removed
    }
    
    /// Removes all elements from the heap.
    @inlinable
    public mutating func removeAll()
    {
        p_elements.removeAll()
        p_indices.removeAll()
    }
    
    /// Removes the last element from the heap.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func removeLast() -> T {
        guard let value = p_elements.last else {
            preconditionFailure("Trying to remove element from empty heap")
        }
        p_indices[value] = nil
        return p_elements.removeLast()
    }
    
    /// Takes a child node and looks at its parents; if a parent is not larger (max-heap) or not smaller (min-heap)
    /// than the child, we exchange them.
    @usableFromInline
    internal mutating func p_shiftUp(_ index: Int) {
        var childIndex = index
        var parentIndex = self.p_parentIndex(of: childIndex)

        while childIndex > 0 && p_isOrderedBefore(p_elements[childIndex], p_elements[parentIndex]) {
            p_swapAt(childIndex, parentIndex)
            childIndex = parentIndex
            parentIndex = self.p_parentIndex(of: childIndex)
        }
    }
    
    @usableFromInline
    internal mutating func p_shiftDown()
    {
        p_shiftDown(0, heapSize: p_elements.count)
    }
    
    /// Looks at a parent node and makes sure it is still larger (max-heap) or smaller (min-heap) than its childeren.
    @usableFromInline
    internal mutating func p_shiftDown(_ index: Int, heapSize: Int) {
        var parentIndex = index
        
        while true {
            let leftChildIndex = self.p_leftChildIndex(of: parentIndex)
            let rightChildIndex = leftChildIndex + 1
            
            // Figure out which comes first if we order them by the sort function:
            // the parent, the left child, or the right child. If the parent comes
            // first, we're done. If not, that element is out-of-place and we make
            // it "float down" the tree until the heap property is restored.
            var first = parentIndex
            if leftChildIndex < heapSize && p_isOrderedBefore(p_elements[leftChildIndex], p_elements[first]) {
                first = leftChildIndex
            }
            if rightChildIndex < heapSize && p_isOrderedBefore(p_elements[rightChildIndex], p_elements[first]) {
                first = rightChildIndex
            }
            if first == parentIndex { return }
            
            p_swapAt(parentIndex, first)
            parentIndex = first
        }
    }
    
    /// Replaces an element in the heap and updates the indices hash.
    @usableFromInline
    internal mutating func p_set(_ newValue: T, at index: Int) {
        p_indices[p_elements[index]] = nil
        p_elements[index] = newValue
        p_indices[newValue] = index
    }
    
    /// Swap two elements in the heap and update the indices hash.
    @usableFromInline
    internal mutating func p_swapAt(_ i: Int, _ j: Int) {
        p_elements.swapAt(i, j)
        p_indices[p_elements[i]] = i
        p_indices[p_elements[j]] = j
    }
    
    /// Returns the index of the parent of the element at index i.
    ///
    /// - Note: The element at index 0 is the root of the tree and has no parent.
    @inline(__always)
    @usableFromInline
    internal func p_parentIndex(of index: Int) -> Int {
        return (index - 1) / 2
    }
    
    /// Returns the index of the left child of the element at index i.
    ///
    /// - Note: this index can be greater than the heap size, in which case there is no left child.
    @inline(__always)
    internal func p_leftChildIndex(of index: Int) -> Int {
        return 2*index + 1
    }
    
    /// Returns the index of the right child of the element at index i.
    ///
    /// - Note: this index can be greater than the heap size, in which case there is no right child.
    @inline(__always)
    internal func p_rightChildIndex(of index: Int) -> Int {
        return 2*index + 2
    }
}
