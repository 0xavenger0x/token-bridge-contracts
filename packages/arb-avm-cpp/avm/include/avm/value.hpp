/*
 * Copyright 2019, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef value_hpp
#define value_hpp

#include <avm/bigint.hpp>
#include <avm/opcodes.hpp>
#include <nonstd/variant.hpp>

enum types { NUM, CODEPT, HASH_ONLY, TUPLE };

class TuplePool;
class Tuple;
struct Operation;
struct CodePoint;

// Note: uint256_t is actually 48 bytes long
using value = nonstd::variant<Tuple, uint256_t, CodePoint>;

struct SerializedValue {
    types type;
    std::string string_value;
};

std::ostream& operator<<(std::ostream& os, const value& val);
uint256_t hash(const value& value);
int get_tuple_size(char*& bufptr);

uint256_t deserialize_int256(char*& srccode);
Operation deserializeOperation(char*& bufptr, TuplePool& pool);
CodePoint deserializeCodePoint(char*& bufptr, TuplePool& pool);
Tuple deserialize_tuple(char*& bufptr, int size, TuplePool& pool);
value deserialize_value(char*& srccode, TuplePool& pool);
void marshal_value(const value& val, std::vector<unsigned char>& buf);
void marshal_Tuple(const Tuple& val, std::vector<unsigned char>& buf);
void marshal_CodePoint(const CodePoint& val, std::vector<unsigned char>& buf);
void marshal_uint256_t(const uint256_t& val, std::vector<unsigned char>& buf);

void marshalShallow(const value& val, std::vector<unsigned char>& buf);
void marshalShallow(const Tuple& val, std::vector<unsigned char>& buf);
void marshalShallow(const CodePoint& val, std::vector<unsigned char>& buf);
void marshalShallow(const uint256_t& val, std::vector<unsigned char>& buf);

template <typename T>
static T shrink(uint256_t i) {
    return static_cast<T>(i & std::numeric_limits<T>::max());
}

uint256_t& assumeInt(value& val);
const uint256_t& assumeInt(const value& val);
uint64_t assumeInt64(uint256_t& val);
Tuple& assumeTuple(value& val);

std::vector<unsigned char> GetHashKey(const value& val);
SerializedValue SerializeValue(const value& val);
CodePoint deserializeCheckpointCodePt(std::vector<unsigned char> val);
uint256_t deserializeCheckpoint256(std::vector<unsigned char> val);

#endif /* value_hpp */
