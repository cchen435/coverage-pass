#include "llvm/Pass.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Support/Debug.h"

using namespace llvm;


namespace {
    typedef std::map<Value *, std::vector<Value *>> CMap;
    typedef std::vector<Value *> VList;
    typedef std::vector<Instruction *> IList;

    const int width = 10;

    struct Coverage : public FunctionPass {
        static char ID;
        Coverage() : FunctionPass(ID) { }
        bool runOnFunction(Function &F) override;
        void getAnalysisUsage(AnalysisUsage &AU) {
            AU.setPreservesCFG();
        }

        void initialize(IList InstList, CMap &map);
        void print(CMap map);
        void print(VList list);
        void concatenate(CMap &map);
    };
}

char Coverage::ID = 0;
static RegisterPass<Coverage> X("coverage", "Coverage of each variable inside a Function",
                                false /* Only looks at CFG */,
                                false /* Analysis Pass */);


bool Coverage::runOnFunction(Function &F)
{
    CMap CoverageSets;

    /* storing unprocessed Instructions */
    IList WorkList;

    /* initialize WorkList with all Instructions */
    for (inst_iterator i = inst_begin(F), e = inst_end(F); i != e; ++i)
        WorkList.push_back(&*i);


    DEBUG_WITH_TYPE("Coverage", errs()<<"Function: " << F.getName() << "\n");
    initialize(WorkList, CoverageSets);

    DEBUG_WITH_TYPE("Coverage", errs() << "before concatenation:\n");
    DEBUG_WITH_TYPE("Coverage", print(CoverageSets));
    DEBUG_WITH_TYPE("Coverage", errs() << "After concatenation:\n");
    concatenate(CoverageSets);
    print(CoverageSets);
    errs() << "\n";

}

// initializing the map. For each instruction, it will create a key:value pair
// key is the definition, and value are a list of operands used in the definition
void Coverage::initialize(IList InstList, CMap &map) {

    IList WorkList = InstList;

    /* Loop over the WorkList to processing each instruction */
    while (!WorkList.empty()) {
        Instruction *I = WorkList.back();
        Value *V = dyn_cast<Value>(I);
        WorkList.pop_back();
        // Terminator instructions normally don't create new definitions, e.g. ret %name.
        // We skip them currently
        if (isa<TerminatorInst>(I)) {
            DEBUG_WITH_TYPE("Coverage", errs() << "Skipping: " << I->getOpcodeName() << "\n");
            continue;
        }

        // Currently have no idea how to handle the following instructions, skip them temporarily
        // ToDo: get correct handle method for these instructions

        // Vector operations: extractelement, insertelement, shufflevector
        if (isa<ShuffleVectorInst>(I) || isa<InsertElementInst>(I) || isa<ExtractElementInst>(I)) {
            DEBUG_WITH_TYPE("Coverage", errs() << "Skipping: " << I->getOpcodeName() << "\n");
            continue;
        }

        // Aggregate operations: extractValue, insertValue
        if (isa<ExtractValueInst>(I) || isa<InsertValueInst>(I)) {
            DEBUG_WITH_TYPE("Coverage", errs() << "Skipping: " << I->getOpcodeName() << "\n");
            continue;
        }

        // Memory Access and Addressing: alloca, load (done), store (done), fence, cmpxchg, atomicrmw, getelementptr
        if (isa<AllocaInst>(I) || isa<FenceInst>(I) || isa<AtomicCmpXchgInst>(I)
            || isa<AtomicRMWInst>(I) || isa<GetElementPtrInst>(I) || isa<LoadInst>(I)) {
            DEBUG_WITH_TYPE("Coverage", errs() << "Skipping: " << I->getOpcodeName() << "\n");
            continue;
        }

        // instruction `store op1, op2` is to move value from op1 to op2
        // therefore, we say op2 will cover op1.
        if (isa<StoreInst>(I)) {
            Value *dst = I->getOperand(1);
            Value *src = I->getOperand(0);

            // first time to use the map element, need to initialize (allocate memory for) it.
            if (map.find(dst) == map.end()) {
                map[dst] = VList();
            }
            map[dst].push_back(src);
            continue;
        }

        // Conversion Operations: trunc .. to, zext, sext, fptrunc, fpext, fptoui, fptosi, bitcast etc.
        if (isa<TruncInst>(I)) {
            DEBUG_WITH_TYPE("Coverage", errs() << "Skipping: " << I->getOpcodeName() << "\n");
            continue;
        }

        // after inline, it may only include intrinsic and library APIs, skip temporary
        // ToDo: handle CallInst better if it is out of assumption
        if (isa<CallInst>(I)) {
            DEBUG_WITH_TYPE("Coverage", errs() << "Skipping: " << I->getOpcodeName() << "\n");
            continue;
        }


        // Other misc operations: landingpad, va_arg, select, call. phi, fcmp and icmp are treated as normal
        if (isa<LandingPadInst>(I) || isa<VAArgInst>(I) || isa<SelectInst>(I)) {
            DEBUG_WITH_TYPE("Coverage", errs() << "Skipping: " << I->getOpcodeName() << "\n");
            continue;
        }


        // following code is to handle all other instructions including
        // binary and shift operations
        // form of c = a op b. They define new definitions.

        // the first time to process the instruction, initialize the data structure
        if (map.find(V) == map.end())
            map[V] = std::vector<Value*>();

        // iterate over each operand in the instruction
        for (Instruction::op_iterator OI = I->op_begin(), OE = I->op_end(); OI != OE; OI++) {
            if (isa<Constant>(OI)) { // operand is a constant
                DEBUG_WITH_TYPE("Coverage", errs() << "Skipping Constant:");
                DEBUG_WITH_TYPE("Coverage", dyn_cast<Constant>(OI)->dump());
                continue;
            }
            // Operand is a LoadInst, we treat load definition equal to its operand.
            if (LoadInst *op = dyn_cast<LoadInst>(OI)) {
                map[V].push_back(dyn_cast<Value>(op->getOperand(0)));
            } else {
                map[V].push_back(dyn_cast<Value>(OI));
            }

            if (Instruction *op = dyn_cast<Instruction>(OI)) {
                WorkList.push_back(op);
            }
        }

        // make sure current Instruction is removed from the WorkList
        WorkList.erase(std::remove(WorkList.begin(), WorkList.end(), I), WorkList.end());
    }
}

// This function is to concatenate the coverage map. If the key of a set is in others values vector,
// It will be appended to the end of that vector
void Coverage::concatenate(CMap &map) {
    VList ToRemove;
    VList ToAppend;
    bool changed = true;

    while(changed) {
        changed = false;

        for (CMap::iterator MB = map.begin(), ME = map.end(); MB != ME; MB++) {
            Value *key = MB->first;
            // remove duplicates
            std::sort(map[key].begin(), map[key].end());
            map[key].erase(std::unique(map[key].begin(), map[key].end()), map[key].end());

            // iterate over each element to check whether it is also a key in the map
            // if yes concatenate that set to the end and mark it to be removed
            for (VList::iterator LI = map[key].begin(), LE = map[key].end(); LI != LE; LI++) {
                if (map.find((*LI)) != map.end()) {
                    ToAppend.insert(ToAppend.end(), map[*LI].begin(), map[*LI].end());
                    ToRemove.push_back(*LI);
                    changed = true;
                }
            }
            // append to the end
            map[key].insert(map[key].end(), ToAppend.begin(), ToAppend.end());
        }

        //remove those has been concatenated
        for (VList::iterator LI = ToRemove.begin(), LE = ToRemove.end(); LI != LE; LI++)
            map.erase(*LI);
        ToRemove.clear();
    }

    // remove duplicates
    for (CMap::iterator MB = map.begin(), ME = map.end(); MB != ME; MB++) {
        Value *key = MB->first;
        std::sort(map[key].begin(), map[key].end());
        map[key].erase(std::unique(map[key].begin(), map[key].end()), map[key].end());

    }

}

void Coverage::print(CMap map) {
    int pos = 0;
    for (CMap::iterator MB = map.begin(), ME = map.end(); MB != ME; MB++) {
        pos=0;
        Value *key = MB->first;
        std::vector<Value *> set = MB->second;

        errs() << "[" << key->getName() << "] covers: \n";
        for (VList::iterator si = set.begin(), se = set.end(); si != se; si++) {
            errs() << "[" << (*si)->getName() << "]";
            /*
            errs() << "[";
            (*si)->print(errs());
            errs() << "]";
             */
            if ((si + 1) != se)
                errs() << ",";

            pos++;
            if (pos % width == 0) {
                pos = 0;
                errs() << "\n";
            }
        }
        errs() << "\n\n";
    }
}

void Coverage::print(VList list) {
    int pos = 0;
    for (VList::iterator LB = list.begin(), LE=list.end(); LB != LE; LB++) {
        errs() << "[" << (*LB)->getName() << "]";
        if ((LB + 1) != LE)
            errs() << ",";

        pos++;
        if (pos % width == 0) {
            pos = 0;
            errs() << "\n";
        }
    }
}
