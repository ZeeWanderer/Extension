//
//  TransactionContext.swift
//  Extension
//
//  Created by zeewanderer on 09.07.2025.
//


public enum TransactionContext
{
    @TaskLocal static var isActive: Bool = false
}
