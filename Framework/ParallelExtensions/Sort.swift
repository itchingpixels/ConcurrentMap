//
//  ParallelSort.swift
//  ParallelExtensions
//
//  Created by Mark Aron Szulyovszky on 20/01/2016.
//  Copyright © 2016 Mark Aron Szulyovszky. All rights reserved.
//

import Foundation

public enum Half {
  case First, Last
}

public extension CollectionType where SubSequence : CollectionType, SubSequence.SubSequence == SubSequence, SubSequence.Generator.Element == Generator.Element, Index == Int, SubSequence.Index == Int {

  public func parallelSort(isOrderedBefore: (Generator.Element, Generator.Element) -> Bool) -> [Generator.Element] {
    
    guard !self.isEmpty else { return Array() }
    guard self.count > 1 else { return Array(self) }
    
    let cpus = numberOfCpus()

    guard cpus == 1 else {
      return self.sort(isOrderedBefore)
    }

    return mergeSort(cpus, threadsRunning: 0, isOrderedBefore: isOrderedBefore)
  }
  
  
  private func merge(var a: [Generator.Element], var b: [Generator.Element], mergeInto acc: [Generator.Element], isOrderedBefore: (Generator.Element, Generator.Element) -> Bool) -> [Generator.Element] {
    guard !a.isEmpty else {
      return acc + b
    }
    guard !b.isEmpty else {
      return acc + a
    }
    
    if isOrderedBefore(a[0], b[0]) {
      a.removeFirst()
      return merge(a, b: b, mergeInto: acc + [a[0]], isOrderedBefore: isOrderedBefore)
    } else {
      b.removeFirst()
      return merge(a, b: b, mergeInto: acc + [b[0]], isOrderedBefore: isOrderedBefore)
    }
  }
  
  private func mergeSort(cpus: Int, threadsRunning: Int, isOrderedBefore: (Generator.Element, Generator.Element) -> Bool) -> [Generator.Element] {
    
    if self.count < 2  { return Array(self) }
    
    var firstHalf: Array<Generator.Element>!
    var secondHalf: Array<Generator.Element>!
    
    if (cpus - threadsRunning) > 0 {
      
      // spawn new queues
      let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
      let group = dispatch_group_create()
      
      dispatch_group_async(group, queue) { () -> Void in
        firstHalf = self.halve(.First).mergeSort(cpus, threadsRunning: threadsRunning+2, isOrderedBefore: isOrderedBefore)
      }
      
      dispatch_group_async(group, queue) { () -> Void in
        secondHalf = self.halve(.Last).mergeSort(cpus, threadsRunning: threadsRunning+2, isOrderedBefore: isOrderedBefore)
      }
      dispatch_group_wait(group, DISPATCH_TIME_FOREVER)

    } else {
      
      firstHalf = self.halve(.First).mergeSort(cpus, threadsRunning: threadsRunning, isOrderedBefore: isOrderedBefore)
      secondHalf = self.halve(.Last).mergeSort(cpus, threadsRunning: threadsRunning, isOrderedBefore: isOrderedBefore)
    
    }
    
    return merge(firstHalf, b: secondHalf, mergeInto: [], isOrderedBefore: isOrderedBefore)
  }


  
  private func halve(half: Half) -> SubSequence {
    if self.count == 2 {
      switch half {
      case .First:
        return self[self.startIndex...self.startIndex]
      case .Last:
        return self[self.endIndex-1...self.endIndex-1]
      }
    } else {
      let middle = self.startIndex + (self.endIndex - self.startIndex)/2
      switch half {
      case .First:
        return self[self.startIndex..<middle]
      case .Last:
        return self[middle..<self.endIndex]
      }
    }
  }

  
  
}

